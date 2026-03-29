# Doto — API Specification
**Version:** 1.0  
**Base URL:** `http://localhost:9000/api` (dev) / `https://api.getdoto.com/api` (prod)  
**Auth:** Bearer JWT on all routes except `/auth/register` and `/auth/login`

---

## Global Conventions

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <jwt>      ← required on all routes except auth
```

### Error Response Shape
All error responses use this shape:
```json
{
  "code": "not_found",
  "message": "Task with id abc-123 not found"
}
```

### Common Error Codes
| HTTP | code | When |
|---|---|---|
| 400 | `validation_error` | Missing required field, invalid value |
| 401 | `unauthorized` | Missing or invalid JWT |
| 403 | `forbidden` | Valid JWT but accessing another family's data |
| 404 | `not_found` | Resource does not exist |
| 409 | `conflict` | Username already taken, invite code not found |
| 500 | `internal_error` | Unexpected server error |

---

## 1. Auth

### POST /api/auth/register
Create a new user account. No auth required.

**Request body:**
```json
{
  "username": "sarah_smith",
  "password": "mypassword123",
  "displayName": "Sarah"
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| username | string | yes | 6–12 chars, alphanumeric + underscore only, unique |
| password | string | yes | Minimum 8 characters |
| displayName | string | yes | 1–100 chars |

**Response `201 Created`:**
```json
{
  "token": "eyJhbGci...",
  "profile": {
    "id": "a1b2c3d4-e5f6-...",
    "username": "sarah_smith",
    "displayName": "Sarah",
    "role": "parent",
    "color": "#6C63FF",
    "points": 0,
    "familyId": null,
    "isAuthAccount": true,
    "createdAt": "2026-03-27T10:00:00Z"
  }
}
```

**Errors:**
- `409 conflict` — username already taken

---

### POST /api/auth/login
Authenticate an existing user. No auth required.

**Request body:**
```json
{
  "username": "sarah_smith",
  "password": "mypassword123"
}
```

**Response `200 OK`:**
```json
{
  "token": "eyJhbGci...",
  "profile": {
    "id": "a1b2c3d4-...",
    "username": "sarah_smith",
    "displayName": "Sarah",
    "role": "parent",
    "color": "#6C63FF",
    "points": 120,
    "familyId": "f1f2f3f4-...",
    "isAuthAccount": true,
    "createdAt": "2026-03-27T10:00:00Z"
  }
}
```

**Errors:**
- `401 unauthorized` — wrong username or password (do not distinguish which)

---

### GET /api/auth/me
Return the currently authenticated user's profile. 🔒 Auth required.

**Response `200 OK`:** Same shape as the `profile` object in login response.

---

---

## 2. Families

### POST /api/families
Create a new family. The calling user becomes the first parent member. 🔒 Auth required.

**Request body:**
```json
{
  "name": "The Smith Family"
}
```

**Response `201 Created`:**
```json
{
  "id": "f1f2f3f4-...",
  "name": "The Smith Family",
  "inviteCode": "DOTO4X",
  "members": [
    {
      "id": "a1b2c3d4-...",
      "displayName": "Sarah",
      "role": "parent",
      "color": "#6C63FF",
      "points": 0,
      "isAuthAccount": true
    }
  ],
  "createdAt": "2026-03-27T10:00:00Z"
}
```

**Errors:**
- `400 validation_error` — name is empty
- `409 conflict` — calling user already belongs to a family

---

### POST /api/families/join
Join an existing family using the invite code. 🔒 Auth required.

**Request body:**
```json
{
  "inviteCode": "DOTO4X"
}
```

**Response `200 OK`:** Same shape as `POST /api/families` response.

**Errors:**
- `404 not_found` — invite code does not match any family
- `409 conflict` — calling user already belongs to a family

---

### GET /api/families/mine
Get the calling user's family with all members. 🔒 Auth required.

**Response `200 OK`:** Same shape as `POST /api/families` response.

**Errors:**
- `404 not_found` — user has no family yet

---

### GET /api/families/mine/invite-code
Get the invite code for the user's family (to share with a second parent). 🔒 Auth required.

**Response `200 OK`:**
```json
{
  "inviteCode": "DOTO4X"
}
```

---

---

## 3. Members (Child Profiles)

Child profiles are not auth accounts. They are created and managed by parents within the family.

### GET /api/members
List all members of the calling user's family. 🔒 Auth required.

**Response `200 OK`:**
```json
[
  {
    "id": "a1b2c3d4-...",
    "displayName": "Sarah",
    "role": "parent",
    "color": "#6C63FF",
    "points": 120,
    "isAuthAccount": true
  },
  {
    "id": "b2c3d4e5-...",
    "displayName": "Jake",
    "role": "child",
    "color": "#FF6B6B",
    "points": 85,
    "isAuthAccount": false
  }
]
```

---

### POST /api/members
Add a child profile to the family. Only parents can call this. 🔒 Auth required.

**Request body:**
```json
{
  "displayName": "Jake",
  "color": "#FF6B6B"
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| displayName | string | yes | 1–100 chars |
| color | string | yes | Valid hex colour string, e.g. `#FF6B6B` |

**Response `201 Created`:**
```json
{
  "id": "b2c3d4e5-...",
  "displayName": "Jake",
  "role": "child",
  "color": "#FF6B6B",
  "points": 0,
  "isAuthAccount": false
}
```

**Errors:**
- `403 forbidden` — calling user is not a parent

---

### PUT /api/members/:id
Update a member's display name or colour. Only parents can call this. 🔒 Auth required.

**Request body:**
```json
{
  "displayName": "Jacob",
  "color": "#4ECDC4"
}
```
All fields optional — send only what you want to change.

**Response `200 OK`:** Updated member object.

**Errors:**
- `403 forbidden` — not a parent, or member is not in the calling user's family
- `404 not_found`

---

### DELETE /api/members/:id
Remove a child profile from the family. Only parents can call this. 🔒 Auth required.  
Note: Cannot delete auth account profiles (parent accounts) via this endpoint.

**Response `204 No Content`**

**Errors:**
- `403 forbidden` — not a parent, or trying to delete an auth account profile
- `404 not_found`

---

---

## 4. Events

### GET /api/events
List events for the family. Supports optional date range filtering. 🔒 Auth required.

**Query parameters:**
| Param | Type | Required | Description |
|---|---|---|---|
| from | ISO 8601 string | no | Filter events starting from this datetime |
| to | ISO 8601 string | no | Filter events ending before this datetime |
| memberId | UUID string | no | Filter events assigned to this member |

**Example:** `GET /api/events?from=2026-03-27T00:00:00Z&to=2026-04-03T00:00:00Z`

**Response `200 OK`:**
```json
[
  {
    "id": "e1e2e3e4-...",
    "familyId": "f1f2f3f4-...",
    "title": "Soccer Practice",
    "description": null,
    "startAt": "2026-03-27T16:00:00Z",
    "endAt": "2026-03-27T17:30:00Z",
    "location": "Riverside Park",
    "color": null,
    "assignedTo": ["b2c3d4e5-..."],
    "createdBy": "a1b2c3d4-...",
    "createdAt": "2026-03-20T09:00:00Z",
    "updatedAt": "2026-03-20T09:00:00Z"
  }
]
```

---

### POST /api/events
Create a new event. 🔒 Auth required.

**Request body:**
```json
{
  "title": "Soccer Practice",
  "description": "Bring water bottle",
  "startAt": "2026-03-27T16:00:00Z",
  "endAt": "2026-03-27T17:30:00Z",
  "location": "Riverside Park",
  "color": null,
  "assignedTo": ["b2c3d4e5-..."]
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| title | string | yes | 1–200 chars |
| description | string | no | Max 1000 chars |
| startAt | ISO 8601 string | yes | |
| endAt | ISO 8601 string | yes | Must be after startAt |
| location | string | no | Max 300 chars |
| color | string | no | Hex colour or null |
| assignedTo | array of UUID strings | no | Must be member IDs within the family |

**Response `201 Created`:** Full event object (same shape as list item above).

**Errors:**
- `400 validation_error` — endAt before startAt, invalid member IDs

---

### GET /api/events/:id
Get a single event. 🔒 Auth required.

**Response `200 OK`:** Single event object.

**Errors:**
- `404 not_found`
- `403 forbidden` — event belongs to a different family

---

### PUT /api/events/:id
Update an event. All fields optional. 🔒 Auth required.

**Request body:** Same shape as POST, all fields optional.

**Response `200 OK`:** Updated event object.

**Errors:**
- `400 validation_error`
- `403 forbidden`
- `404 not_found`

---

### DELETE /api/events/:id
Delete an event. 🔒 Auth required.

**Response `204 No Content`**

**Errors:**
- `403 forbidden`
- `404 not_found`

---

---

## 5. Tasks

### GET /api/tasks
List tasks for the family. Supports filtering. 🔒 Auth required.

**Query parameters:**
| Param | Type | Required | Description |
|---|---|---|---|
| assignedTo | UUID string | no | Filter by assigned member |
| status | string | no | `todo`, `in_progress`, `done`, `cancelled` |
| priority | string | no | `low`, `medium`, `high` |

**Response `200 OK`:**
```json
[
  {
    "id": "t1t2t3t4-...",
    "familyId": "f1f2f3f4-...",
    "title": "Take out bins",
    "description": null,
    "assignedTo": "b2c3d4e5-...",
    "status": "todo",
    "priority": "medium",
    "points": 10,
    "dueAt": "2026-03-28T18:00:00Z",
    "completedAt": null,
    "createdBy": "a1b2c3d4-...",
    "createdAt": "2026-03-27T09:00:00Z",
    "updatedAt": "2026-03-27T09:00:00Z"
  }
]
```

---

### POST /api/tasks
Create a task. 🔒 Auth required.

**Request body:**
```json
{
  "title": "Take out bins",
  "description": null,
  "assignedTo": "b2c3d4e5-...",
  "priority": "medium",
  "points": 10,
  "dueAt": "2026-03-28T18:00:00Z"
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| title | string | yes | 1–200 chars |
| description | string | no | |
| assignedTo | UUID string | no | Must be a family member |
| priority | string | no | `low`, `medium`, `high` — default `medium` |
| points | integer | no | >= 0, default 0 |
| dueAt | ISO 8601 string | no | |

**Response `201 Created`:** Full task object.

---

### GET /api/tasks/:id
Get a single task. 🔒 Auth required.

**Response `200 OK`:** Single task object.

---

### PUT /api/tasks/:id
Update a task. All fields optional. 🔒 Auth required.

**Request body:** Same fields as POST, all optional.

**Response `200 OK`:** Updated task object.

---

### PATCH /api/tasks/:id/complete
Mark a task as done. Sets `status = done`, `completedAt = now()`, and awards points to the assigned member. 🔒 Auth required.

**Request body:** None.

**Response `200 OK`:** Updated task object with `status: "done"` and `completedAt` set.

**Side effect:** If `task.points > 0` and `task.assignedTo` is set, `profiles.points` for that member is incremented by `task.points`.

---

### DELETE /api/tasks/:id
Delete a task. 🔒 Auth required.

**Response `204 No Content`**

---

---

## 6. Shopping Lists

### GET /api/shopping/lists
List all shopping lists for the family. 🔒 Auth required.

**Response `200 OK`:**
```json
[
  {
    "id": "l1l2l3l4-...",
    "familyId": "f1f2f3f4-...",
    "name": "Groceries",
    "itemCount": 12,
    "checkedCount": 3,
    "createdBy": "a1b2c3d4-...",
    "createdAt": "2026-03-20T09:00:00Z",
    "updatedAt": "2026-03-27T14:00:00Z"
  }
]
```

Note: `itemCount` and `checkedCount` are computed counts — not stored columns.

---

### POST /api/shopping/lists
Create a new shopping list. 🔒 Auth required.

**Request body:**
```json
{
  "name": "Groceries"
}
```

**Response `201 Created`:** Shopping list object (itemCount and checkedCount will be 0).

**Errors:**
- `400 validation_error` — name empty

---

### DELETE /api/shopping/lists/:id
Delete a shopping list and all its items. 🔒 Auth required.

**Response `204 No Content`**

---

### GET /api/shopping/lists/:id/items
Get all items in a shopping list. 🔒 Auth required.

**Response `200 OK`:**
```json
[
  {
    "id": "i1i2i3i4-...",
    "listId": "l1l2l3l4-...",
    "familyId": "f1f2f3f4-...",
    "name": "Whole milk",
    "category": "dairy",
    "quantity": "2 litres",
    "isChecked": false,
    "checkedBy": null,
    "checkedAt": null,
    "createdBy": "a1b2c3d4-...",
    "createdAt": "2026-03-27T09:00:00Z",
    "updatedAt": "2026-03-27T09:00:00Z"
  }
]
```

Items are returned sorted by: `is_checked ASC` (unchecked first), then `category ASC`, then `name ASC`.

---

### POST /api/shopping/lists/:id/items
Add an item to a shopping list. 🔒 Auth required.

**Request body:**
```json
{
  "name": "Whole milk",
  "category": "dairy",
  "quantity": "2 litres"
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| name | string | yes | 1–200 chars |
| category | string | no | One of the 9 category values, default `other` |
| quantity | string | no | Free text, e.g. "500g", "1 dozen" |

**Response `201 Created`:** Full item object.

---

### PATCH /api/shopping/lists/:listId/items/:itemId/check
Toggle an item's checked state. 🔒 Auth required.

**Request body:**
```json
{
  "isChecked": true
}
```

**Response `200 OK`:** Updated item object with `isChecked`, `checkedBy`, and `checkedAt` set (or cleared if unchecking).

---

### DELETE /api/shopping/lists/:listId/items/:itemId
Delete a single item. 🔒 Auth required.

**Response `204 No Content`**

---

### DELETE /api/shopping/lists/:id/items/checked
Remove all checked items from a list (the "clear checked" action). 🔒 Auth required.

**Response `200 OK`:**
```json
{
  "deletedCount": 5
}
```

---

---

## 7. Rewards

### GET /api/rewards
List rewards for the family. Supports filtering by member and status. 🔒 Auth required.

**Query parameters:**
| Param | Type | Description |
|---|---|---|
| memberId | UUID | Filter to one child's rewards |
| status | string | `active`, `pending_approval`, `approved`, `redeemed` |

**Response `200 OK`:**
```json
[
  {
    "id": "r1r2r3r4-...",
    "familyId": "f1f2f3f4-...",
    "memberId": "b2c3d4e5-...",
    "title": "Movie night",
    "pointsCost": 100,
    "status": "active",
    "requestedAt": null,
    "approvedBy": null,
    "approvedAt": null,
    "createdAt": "2026-03-20T09:00:00Z",
    "updatedAt": "2026-03-20T09:00:00Z"
  }
]
```

---

### POST /api/rewards
Create a reward goal (parent creates on behalf of a child, or child's view sends this). 🔒 Auth required.

**Request body:**
```json
{
  "memberId": "b2c3d4e5-...",
  "title": "Movie night",
  "pointsCost": 100
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| memberId | UUID | yes | Must be a child member in the family |
| title | string | yes | 1–200 chars |
| pointsCost | integer | yes | > 0 |

**Response `201 Created`:** Full reward object.

---

### PATCH /api/rewards/:id/request
Child requests to redeem a reward. Sets status to `pending_approval`. 🔒 Auth required.

**Request body:** None.

**Response `200 OK`:** Updated reward object with `status: "pending_approval"` and `requestedAt` set.

**Errors:**
- `400 validation_error` — reward is not in `active` status
- `409 conflict` — member does not have enough points

---

### PATCH /api/rewards/:id/approve
Parent approves a reward redemption request. Sets status to `approved`. 🔒 Auth required.

**Request body:** None.

**Response `200 OK`:** Updated reward object with `status: "approved"`, `approvedBy`, and `approvedAt` set.

**Errors:**
- `403 forbidden` — calling user is not a parent
- `400 validation_error` — reward is not in `pending_approval` status

---

### PATCH /api/rewards/:id/redeem
Parent marks reward as redeemed (the reward has been given to the child). Sets status to `redeemed`. 🔒 Auth required.

**Request body:** None.

**Response `200 OK`:** Updated reward with `status: "redeemed"`.

**Errors:**
- `403 forbidden` — calling user is not a parent
- `400 validation_error` — reward is not in `approved` status

---

### DELETE /api/rewards/:id
Delete a reward goal. Only parents or the member who owns it can delete. 🔒 Auth required.

**Response `204 No Content`**

---

---

## 8. Dashboard

The dashboard endpoint returns a pre-assembled snapshot so the iOS app makes one call instead of several.

### GET /api/dashboard
Get today's dashboard data for the calling user's family. 🔒 Auth required.

**Response `200 OK`:**
```json
{
  "family": {
    "id": "f1f2f3f4-...",
    "name": "The Smith Family",
    "members": [
      {
        "id": "a1b2c3d4-...",
        "displayName": "Sarah",
        "role": "parent",
        "color": "#6C63FF",
        "points": 120
      }
    ]
  },
  "todaysEvents": [
    {
      "id": "e1e2e3e4-...",
      "title": "Soccer Practice",
      "startAt": "2026-03-27T16:00:00Z",
      "endAt": "2026-03-27T17:30:00Z",
      "assignedTo": ["b2c3d4e5-..."],
      "color": null
    }
  ],
  "pendingTasks": [
    {
      "id": "t1t2t3t4-...",
      "title": "Take out bins",
      "assignedTo": "b2c3d4e5-...",
      "priority": "medium",
      "points": 10,
      "dueAt": "2026-03-28T18:00:00Z"
    }
  ],
  "pendingApprovals": [
    {
      "id": "r1r2r3r4-...",
      "memberId": "b2c3d4e5-...",
      "title": "Movie night",
      "pointsCost": 100,
      "status": "pending_approval"
    }
  ]
}
```

Notes:
- `todaysEvents` — events where `start_at` falls within today (family's server date, UTC)
- `pendingTasks` — tasks with `status IN ('todo', 'in_progress')` for all family members
- `pendingApprovals` — rewards with `status = 'pending_approval'` (shown to parents only — return empty array for child callers)

---

---

## 9. Play Routes File

```
# conf/routes

# Health
GET     /api/health                                   controllers.HealthController.check

# Auth (no JWT required)
POST    /api/auth/register                            controllers.AuthController.register
POST    /api/auth/login                               controllers.AuthController.login
GET     /api/auth/me                                  controllers.AuthController.me

# Family
POST    /api/families                                 controllers.FamilyController.create
POST    /api/families/join                            controllers.FamilyController.join
GET     /api/families/mine                            controllers.FamilyController.mine
GET     /api/families/mine/invite-code                controllers.FamilyController.inviteCode

# Members
GET     /api/members                                  controllers.MemberController.list
POST    /api/members                                  controllers.MemberController.create
PUT     /api/members/:id                              controllers.MemberController.update(id: String)
DELETE  /api/members/:id                              controllers.MemberController.delete(id: String)

# Events
GET     /api/events                                   controllers.EventController.list(from: Option[String], to: Option[String], memberId: Option[String])
POST    /api/events                                   controllers.EventController.create
GET     /api/events/:id                               controllers.EventController.get(id: String)
PUT     /api/events/:id                               controllers.EventController.update(id: String)
DELETE  /api/events/:id                               controllers.EventController.delete(id: String)

# Tasks
GET     /api/tasks                                    controllers.TaskController.list(assignedTo: Option[String], status: Option[String], priority: Option[String])
POST    /api/tasks                                    controllers.TaskController.create
GET     /api/tasks/:id                                controllers.TaskController.get(id: String)
PUT     /api/tasks/:id                                controllers.TaskController.update(id: String)
PATCH   /api/tasks/:id/complete                       controllers.TaskController.complete(id: String)
DELETE  /api/tasks/:id                                controllers.TaskController.delete(id: String)

# Shopping
GET     /api/shopping/lists                           controllers.ShoppingController.listLists
POST    /api/shopping/lists                           controllers.ShoppingController.createList
DELETE  /api/shopping/lists/:id                       controllers.ShoppingController.deleteList(id: String)
GET     /api/shopping/lists/:id/items                 controllers.ShoppingController.listItems(id: String)
POST    /api/shopping/lists/:id/items                 controllers.ShoppingController.addItem(id: String)
PATCH   /api/shopping/lists/:listId/items/:itemId/check  controllers.ShoppingController.checkItem(listId: String, itemId: String)
DELETE  /api/shopping/lists/:listId/items/:itemId     controllers.ShoppingController.deleteItem(listId: String, itemId: String)
DELETE  /api/shopping/lists/:id/items/checked         controllers.ShoppingController.clearChecked(id: String)

# Rewards
GET     /api/rewards                                  controllers.RewardController.list(memberId: Option[String], status: Option[String])
POST    /api/rewards                                  controllers.RewardController.create
PATCH   /api/rewards/:id/request                      controllers.RewardController.request(id: String)
PATCH   /api/rewards/:id/approve                      controllers.RewardController.approve(id: String)
PATCH   /api/rewards/:id/redeem                       controllers.RewardController.redeem(id: String)
DELETE  /api/rewards/:id                              controllers.RewardController.delete(id: String)

# Dashboard
GET     /api/dashboard                                controllers.DashboardController.get
```
