# Attachments — the shared store

Verified against the live API on 2026-08-17.

## The endpoints

| Endpoint | Body | Notes |
|---|---|---|
| `POST /api/attachment/upload` | multipart: `compid`, `modulekey`, `recordid`, `file` (+ `userid`) | one file per call |
| `POST /api/attachment/list` | json: `compid`, `modulekey`, `recordid` | returns the rows below |
| `POST /api/attachment/delete` | json: `compid`, `id` | `id` = the row's `Id` |

`list` returns:

```json
{ "Id": 8, "FileName": "Screenshot (1).png", "FileExt": "png", "FileSize": 320580,
  "ObjectKey": "company-2/Task/44/20260817164240063_Screenshot (1).png",
  "UploadedByName": "Ankit", "UploadedDate": "2026-08-17 16:42",
  "Url": "https://digitalerp.s3.ap-northeast-1.amazonaws.com/…?X-Amz-Expires=3600&…" }
```

`Url` is **presigned and expires after 1 hour** — always re-fetch on screen open,
never persist it.

## ⚠️ modulekey is not validated

```
modulekey "Task"        → real files
modulekey "ZZZNONSENSE" → {"success":true,"data":[]}
```

Any string is accepted, and it becomes the S3 folder name. A key the web ERP
doesn't read means uploads "succeed" and the file is invisible forever — the
same silent-drop failure this app has hit before. **Never guess a key.**

Confirmed so far: **`Task`** only. Everything else is pending an answer from the
backend team (see the question at the bottom).

## Wiring a module (the recipe)

Attachments are keyed by the record's id, so on a *create* form files must be
queued and uploaded only after the record is saved. `Task` is the reference
implementation — copy it:

1. **Controller** — hold picked files, upload after save:
   ```dart
   final List<PickedAttachment> pendingAttachments = [];   // create form
   List<AttachmentItem> attachments = [];                  // detail screen

   // after the save call returns the new id:
   await AttachmentRepo.upload(filePath: f.path, compid: _compId,
       modulekey: AttachmentModule.task, recordid: newId, userid: _userId);

   // on detail load:
   attachments = await AttachmentRepo.list(compid: _compId,
       modulekey: AttachmentModule.task, recordid: recordId);
   ```
   See `lib/screen/ui/home/task_module/task_controller.dart`.

2. **Create screen** — queue files with `pickAttachments()` (the shared
   Camera / Gallery / Files sheet), show them as removable chips. Do **not**
   upload on pick.

3. **Detail screen** — list `attachments` with tap-to-open via `launchUrl`,
   an Add button, and delete. See `task_detail_screen.dart` → `_attachmentsCard`.

## Current state per module

| Module | Attachments today | Action |
|---|---|---|
| **Task** | ✅ new store, working | done |
| MRN, GRN, Indent, old Task-mgmt | ❌ silently dropped | migrate once the key is known |
| Purchase Order, Performa Invoice | ✅ works — uploads with `storage=s3` to `/api/UploadReimbursementFile`, saves the returned `key` on the document, ERP renders it | **do not move** until the ERP is confirmed to read this store |
| Reimbursement, Payment Request, Attendance selfie, TapCard | ✅ works via their own save endpoints | leave alone unless the backend says otherwise |

## Open question for the backend team

> For `/api/attachment/upload` and `/api/attachment/list`, what is the exact
> `modulekey` string for each module — Purchase Order, Performa Invoice / Sale
> Order, MRN, GRN, Indent, Reimbursement, Payment Request, Visit, Approval?
> The API accepts any string without validating it, so a mismatch means files
> upload fine and never appear in the ERP.
>
> Also: does the web ERP read this attachment table for those modules, or still
> the file key saved on the document itself? PO and Performa work today via the
> document key, so we don't want to move them if the ERP hasn't switched.

Answer these and each module is roughly a 30-line change following the recipe above.
