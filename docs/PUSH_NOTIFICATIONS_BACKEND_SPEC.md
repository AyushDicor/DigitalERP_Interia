# Task-assignment push notifications — what the API needs to do

**For:** the NewDigitalErp mobile API team
**Goal:** the moment user A assigns a task to user B, user B's phone shows
"New task assigned to you" — even if the app is closed.

**Scope of this work: 2 new things, no database change.**

| | |
|---|---|
| New DB table | ❌ none |
| New endpoints | ❌ none |
| New file | ✅ one — `Helpers/PushService.cs` |
| Existing file touched | ✅ one — 4 lines at the end of `TaskController.Create()` |
| Needed from the client | 🔑 the Firebase service-account key (step 1) |

The **app side is already built**. It subscribes each logged-in user to their own
Firebase topic, receives the push, draws the notification and opens the task when
tapped. Nothing more is needed there beyond shipping the new APK.

---

## How it works

Firebase has a feature called **topics** — a named channel that devices can listen on.
On login the app subscribes to a topic named after the user:

```
user_<compid>_<userid>        e.g. user_2_6   (company 2, user id 6 = tb_login.UserId)
```

So the API never needs to know anything about device tokens, phones, or installs.
To notify user 6 of company 2, it just sends to `user_2_6`. Firebase handles the rest.

```
user A creates a task
  POST /api/task/create ──► CreateTask proc (unchanged)
                            then: send to topic "user_2_<assigneeid>" ──► Firebase
                                                                            │
user B's phone  ◄─────────────────────────────────────── push delivered ────┘
  "New task assigned to you"    (app open, closed, or phone locked)
  tap → opens that task
```

---

## Step 1 — Firebase service-account key

*This one is on the client, not the dev — but nothing can be tested until it exists.*

Google switched off the old "FCM server key" in 2024. Sending now uses the
**FCM HTTP v1 API**, which authenticates with a service account.

1. Firebase Console → project **digitalerp-dicor** → ⚙ Project settings → **Service accounts**
2. **Generate new private key** → downloads a JSON file
3. Put it on the API server, e.g. `App_Data/fcm-service-account.json` — keep it out of source control, it is a credential
4. Confirm **Firebase Cloud Messaging API (V1)** is *Enabled* in Cloud Console → APIs
5. The server must be able to reach `oauth2.googleapis.com` and `fcm.googleapis.com` over HTTPS — check the firewall, this is the usual silent blocker

`appsettings.json`:

```json
"Firebase": {
  "ProjectId": "digitalerp-dicor",
  "ServiceAccountPath": "App_Data/fcm-service-account.json"
}
```

> **iOS only:** also upload the APNs auth key (.p8) under Firebase → Cloud Messaging,
> or iPhones subscribe fine and then never receive anything. Android needs nothing extra.

### Smoke-test it before writing any code

Once an APK with topic support is installed and someone has logged in, you can prove the
whole delivery path works without a single line of C#:

Firebase Console → **Messaging** → *Create campaign* → **Firebase notification message** →
compose anything → *Target*: **Topic** → enter `user_2_6` (use a real compid/userid) → send.

If that phone buzzes, everything below is just automating the same call.

---

## Step 2 — the sender

No NuGet package needed. FCM v1 wants a Google OAuth access token; you get one by
signing a JWT with the service account's private key and exchanging it — about 80 lines
using only `System.Text.Json` and `System.Security.Cryptography`.

New file `Helpers/PushService.cs`:

```csharp
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace NewDigitalErpMobileApi.Helpers
{
    public interface IPushService
    {
        Task SendToUserAsync(int compid, int userid, string title, string body,
                             Dictionary<string, string>? data = null);
    }

    /// Sends notifications through the FCM HTTP v1 API, addressed to the
    /// per-user topic the app subscribes to. Every failure is swallowed: a push
    /// that doesn't go out must never fail the request that triggered it.
    public class PushService : IPushService
    {
        private static readonly HttpClient Http = new();
        private readonly IConfiguration _cfg;
        private readonly ILogger<PushService> _log;

        private static string? _accessToken;
        private static DateTime _accessTokenExpiry = DateTime.MinValue;

        public PushService(IConfiguration cfg, ILogger<PushService> log)
        { _cfg = cfg; _log = log; }

        public async Task SendToUserAsync(int compid, int userid, string title, string body,
                                          Dictionary<string, string>? data = null)
        {
            try
            {
                var projectId = _cfg["Firebase:ProjectId"];
                if (string.IsNullOrWhiteSpace(projectId)) return;

                var accessToken = await GetAccessTokenAsync();
                if (accessToken is null) return;

                // The topic the app subscribed to on login. Must match exactly.
                string topic = $"user_{compid}_{userid}";

                var payload = new
                {
                    message = new
                    {
                        topic,
                        notification = new { title, body },
                        data = data ?? new Dictionary<string, string>(),
                        android = new
                        {
                            priority = "HIGH",
                            notification = new { channel_id = "task_assignments" }
                        },
                        apns = new { payload = new { aps = new { sound = "default" } } }
                    }
                };

                var req = new HttpRequestMessage(HttpMethod.Post,
                    $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send")
                {
                    Content = new StringContent(JsonSerializer.Serialize(payload),
                                                Encoding.UTF8, "application/json")
                };
                req.Headers.Add("Authorization", "Bearer " + accessToken);

                var res = await Http.SendAsync(req);
                if (!res.IsSuccessStatusCode)
                    _log.LogWarning("FCM send failed {Status}: {Body}",
                                    res.StatusCode, await res.Content.ReadAsStringAsync());
            }
            catch (Exception ex) { _log.LogWarning(ex, "Push send skipped"); }
        }

        /// Google OAuth token from the service account (cached ~55 min).
        private async Task<string?> GetAccessTokenAsync()
        {
            if (_accessToken is not null && DateTime.UtcNow < _accessTokenExpiry)
                return _accessToken;

            var path = _cfg["Firebase:ServiceAccountPath"];
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path)) return null;

            using var doc = JsonDocument.Parse(await File.ReadAllTextAsync(path));
            string clientEmail = doc.RootElement.GetProperty("client_email").GetString()!;
            string privateKey  = doc.RootElement.GetProperty("private_key").GetString()!;

            long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            string header = B64(JsonSerializer.Serialize(new { alg = "RS256", typ = "JWT" }));
            string claims = B64(JsonSerializer.Serialize(new
            {
                iss   = clientEmail,
                scope = "https://www.googleapis.com/auth/firebase.messaging",
                aud   = "https://oauth2.googleapis.com/token",
                iat   = now,
                exp   = now + 3600
            }));

            using var rsa = RSA.Create();
            rsa.ImportFromPem(privateKey);
            string signature = B64Url(rsa.SignData(Encoding.UTF8.GetBytes($"{header}.{claims}"),
                                      HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
            string jwt = $"{header}.{claims}.{signature}";

            var res = await Http.PostAsync("https://oauth2.googleapis.com/token",
                new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    ["assertion"]  = jwt
                }));
            if (!res.IsSuccessStatusCode) return null;

            using var tok = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
            _accessToken = tok.RootElement.GetProperty("access_token").GetString();
            _accessTokenExpiry = DateTime.UtcNow.AddMinutes(55);
            return _accessToken;

            static string B64(string s) => B64Url(Encoding.UTF8.GetBytes(s));
            static string B64Url(byte[] b) =>
                Convert.ToBase64String(b).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }
    }
}
```

Register it in `Program.cs`, beside the existing registrations:

```csharp
builder.Services.AddSingleton<IPushService, PushService>();
```

---

## Step 3 — fire it when a task is assigned

`Controllers/TaskController.cs` — inject `IPushService _push` in the constructor
(same pattern as `IDbHelper`), then add this at the **end** of `Create()`, after the
task is saved:

```csharp
var row = await _db.ProcPlatformFirstAsync("CreateTask", args);
int newId = 0;
if (row is not null && ((IDictionary<string, object>)row).TryGetValue("NewTaskId", out var v))
    int.TryParse(v?.ToString(), out newId);

// ── Notify the assignee (best-effort; must never break task creation) ──
int assigneeId = NullableInt(p, "assigneeid") ?? 0;
if (newId > 0 && assigneeId > 0 && assigneeId != userid)   // don't ping yourself
{
    string creator  = Str(p, "username") ?? Str(p, "createdbyname") ?? "";
    string bodyText = title.Trim();
    if (creator.Length > 0) bodyText += " · from " + creator;
    var priority = Str(p, "priority");
    if (!string.IsNullOrWhiteSpace(priority)) bodyText += " · " + priority;

    await _push.SendToUserAsync(compid, assigneeId,
        "New task assigned to you", bodyText,
        new Dictionary<string, string>
        {
            ["module"] = "task",              // see the module table below
            ["id"]     = newId.ToString()
        });
}

return ApiOk(new Dictionary<string, object?> { ["taskid"] = newId }, "Task created successfully.");
```

### The payload keys the app depends on

Please keep these exactly as written — the app reads them by name.

| key | value | what breaks without it |
|---|---|---|
| `message.topic` | `user_<compid>_<userid>` of the **assignee** | the wrong person, or nobody, gets it |
| **`data.module`** | module key — see the table below | the app can't tell which screen to open |
| **`data.id`** | the record's id, **as a string** | tapping opens the module's list instead of the record |
| `android.notification.channel_id` | `task_assignments` | notification arrives silent — no sound, no heads-up |
| `notification.title` / `.body` | the shown text | nothing is drawn while the app is closed |

### One payload for every module

`module` + `id` is deliberately generic: **the app needs no change to support another
module**, as long as that module is already in its table (all the ones below are).
So notifying about, say, an indent later is a backend-only change.

| `data.module` | opens |
|---|---|
| `task` | that task's detail screen |
| `visit` | that visit's detail screen |
| `approval` | the approval list |
| `reimbursement` | the reimbursement list |
| `payment` | the payment-request list |
| `mrn` / `grn` / `indent` | that module's list |
| `purchaseorder` / `saleorder` | that module's list |
| `lead` | the lead list |

Only `task` and `visit` open the exact record today — the other detail screens are
driven by their list and can't be opened from an id alone. They still land the user
in the right module. (Fixable per module later on the app side; no backend impact.)

An unrecognised `module` is harmless: the notification is still shown with its
title and body, and tapping simply does nothing — useful when a user is on an
older APK than the backend.

The older `data.taskid` / `data.visitid` keys still work, so nothing breaks if
they're already in use, but new work should send `module` + `id`.

---

## Testing, in this order

1. **Topic delivery works** — send by hand from the Firebase Console to `user_2_<userid>` (see step 1). If this fails, nothing else will work; it's the key, the APNs setup, or the app install.
2. **Automatic send works** — from one account, create a task assigned to another user. Their phone should buzz within a second or two.
3. **If nothing arrives** — check the API log for `FCM send failed`; the response body names the cause. Then: is the service-account file readable by the app-pool identity? Can the server reach `fcm.googleapis.com`? Is the app's notification permission on in Android settings?

---

## Notes

- **Nothing to store.** No table, no tokens, no cleanup job. Firebase keeps the
  subscription list. If a user reinstalls or changes phone, the app re-subscribes on
  next login by itself.
- **The APK matters.** Topic subscription ships in the new app build — an older
  installed APK will never receive these. Coordinate the release.
- **Alternative if topics are ever unsuitable** (e.g. you later want to know exactly
  which devices are registered): the same `PushService` can address individual device
  tokens instead, but that needs a `MobileDeviceToken` table and a register endpoint.
  Topics avoid both; only switch if there's a reason.
- **Same plumbing, cheap to extend** once `PushService` exists — one call each:
  task status change or new followup → notify the other party; approval raised →
  notify the approver; approval decided → notify whoever requested it.
