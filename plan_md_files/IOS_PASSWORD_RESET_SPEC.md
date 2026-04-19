# iOS Password Reset & Email Management Spec

This document outlines the iOS implementation requirements for the password reset and email management features.

---

## 1. Password Reset Flow (Parents)

### Overview
Parents can reset their own password using a 6-digit code sent to their registered email address. This flow is for parent accounts only.

### Flow
1. User taps "Forgot Password?" on login screen
2. User enters their email address
3. App sends request to backend → receives 200 OK (even if email doesn't exist)
4. User receives email with 6-digit code
5. User enters code + new password in app
6. App validates and resets password

### API Endpoints

#### Step 1: Request Reset Code
```
POST /api/auth/request-reset
Content-Type: application/json

Request:
{
  "email": "parent@example.com"
}

Response 200 OK:
{
  "sent": true
}

Errors:
- 400 validation_error - Invalid email format
```

**iOS Implementation Notes:**
- Show "Check your email" message immediately after 200 response
- Don't reveal if email exists or if the email belongs to a child account (backend always returns 200)
- Include "Resend code" option (calls same endpoint)
- Only show forgot-password entry points on parent login flows

#### Step 2: Reset Password with Code
```
POST /api/auth/reset-password
Content-Type: application/json

Request:
{
  "code": "123456",
  "newPassword": "newpassword123"
}

Response 200 OK:
{
  "reset": true
}

Errors:
- 400 validation_error - Password < 8 characters
- 400 invalid_code - Code doesn't exist
- 400 expired_code - Code expired (15 min)
- 400 already_used - Code already used
```

**iOS Implementation Notes:**
- Validate password length (≥8 chars) client-side before sending
- Show "Invalid or expired code" for both invalid/expired codes (security)
- Auto-dismiss on success, return to login screen
- Clear code input fields after failed attempt
- Use numeric keyboard for the 6-digit code input

### UI Screens Required
1. **Forgot Password Screen** - Email input, Submit button
2. **Verify Code Screen** - 6-digit code input (individual boxes or single field), Resend option
3. **New Password Screen** - Password field, Confirm password field, Show/hide toggle
4. **Success Screen** - Confirmation, Return to login button

---

## 2. Parent-Initiated Child Password Reset

### Overview
Parents can reset child passwords directly from the member management screen without needing email.

### Flow
1. Parent navigates to member profile/settings
2. Taps "Reset Password" for child
3. Enters new password
4. Child can now login with new password

### API Endpoint
```
POST /api/members/:id/reset-password
Authorization: Bearer <parent_token>
Content-Type: application/json

Request:
{
  "newPassword": "newpassword123"
}

Response 200 OK:
{
  "reset": true
}

Errors:
- 403 forbidden - Caller is not a parent or member not in same family
- 400 validation_error - Password < 8 characters
- 404 not_found - Member doesn't exist
```

**iOS Implementation Notes:**
- Only show "Reset Password" button to parents (hide for children viewing other profiles)
- Only show this action for child members
- Show confirmation dialog before resetting
- Display success toast/message
- No email involved - immediate reset

### UI
- Add "Reset Password" button in member profile/settings (parent-only)
- Present alert/modal with password field
- Confirm password field for safety

---

## 3. Email in Registration

### Overview
Parents must provide an email during registration for future password recovery. Children must not provide an email.

### API Endpoint
```
POST /api/auth/register
Content-Type: application/json

Request (Parent):
{
  "username": "parent1",
  "password": "password123",
  "displayName": "John Doe",
  "role": "parent",
  "email": "john@example.com"
}

Request (Child - no email):
{
  "username": "child1",
  "password": "password123",
  "displayName": "Jane Doe",
  "role": "child",
  "inviteCode": "ABC123"
  // No email field needed
}

Response 201 Created:
{
  "token": "jwt_token",
  "profile": {
    "id": "...",
    "username": "parent1",
    "email": "john@example.com",
    ...
  }
}

Errors:
- 400 validation_error - Email required for parent accounts
- 400 validation_error - Invalid email format
- 400 validation_error - Email is only supported for parent accounts
- 409 conflict - Email already in use
```

**iOS Implementation Notes:**
- Add required email field to parent registration form
- Do not show an email field on child registration form
- Validate email format client-side
- Store returned email in user session
- Show helper text like `Used for password recovery`

---

## 4. Email Management in Profile

### Overview
Only parents can manage their recovery email from profile settings.

### API Endpoints

#### Update Profile (AuthController)
```
PATCH /api/auth/profile
Authorization: Bearer <token>
Content-Type: application/json

Request:
{
  "displayName": "New Name",
  "color": "#185FA5",
  "email": "newemail@example.com"  // Optional, null to remove
}

Response 200 OK:
{
  "id": "...",
  "username": "parent1",
  "email": "newemail@example.com",
  ...
}

Errors:
- 400 validation_error - Invalid email format
- 400 validation_error - Email is only supported for parent accounts
- 409 conflict - Email already in use by another account
```

#### Update Me (ProfileController)
```
PATCH /api/profiles/me
Authorization: Bearer <token>
Content-Type: application/json

Request:
{
  "displayName": "New Name",
  "color": "#185FA5",
  "email": "newemail@example.com"  // Optional
}
```

**iOS Implementation Notes:**
- Add email field to parent profile/settings screens only
- Do not show recovery email editing for children
- Allow clearing email only if product approves that behavior; backend currently accepts clearing but parent registration requires one on signup
- Validate format before sending
- Update local profile cache after successful update
- Show `Used for password recovery` helper text

---

## 5. Reward Creation Fix

### Overview
`memberId` is now optional in reward creation. Children can only create rewards for themselves.

### API Endpoint
```
POST /api/rewards
Authorization: Bearer <token>
Content-Type: application/json

Request (Child creating for self - memberId omitted):
{
  "title": "Ice Cream",
  "pointsCost": 50,
  "emoji": "🍦"
  // memberId omitted - defaults to caller
}

Request (Parent creating for child):
{
  "memberId": "child-uuid",
  "title": "Ice Cream",
  "pointsCost": 50,
  "emoji": "🍦"
}

Errors:
- 403 forbidden - Child trying to create reward for another member
```

**iOS Implementation Notes:**
- For child users: Don't show member selector, always omit `memberId`
- For parent users: Show member selector, include `memberId` when creating for specific child
- Backend will reject if child tries to specify different memberId

---

## 6. Error Handling Summary

### Common Error Codes
| Code | Message | Action |
|------|---------|--------|
| `validation_error` | Field validation failed | Show inline error on field |
| `invalid_code` | Invalid or expired code | Show generic "Invalid code" message |
| `expired_code` | Code has expired | Show "Code expired, request new one" |
| `already_used` | Code already used | Show "Code already used, request new one" |
| `conflict` | Email/username taken | Show error, suggest alternatives |
| `forbidden` | Not allowed | Hide UI element or show permission error |
| `unauthorized` | Token invalid/expired | Redirect to login |

### Password Reset Specific
- Always show "Check your email" after `request-reset` (even if email not found)
- Treat child accounts exactly like non-existent email accounts in the UI
- Don't distinguish between invalid/expired codes to prevent enumeration
- Clear code input after failed attempt (but keep email)
- Use numeric keyboard for the 6-digit code input

---

## 7. Security Considerations

1. **Timing Attacks**: Backend has 200ms fixed delay on `request-reset`. Don't show different UI based on response time.

2. **Code Enumeration**: Don't reveal if code is invalid vs expired. Use generic message.

3. **JWT Invalidation**: After password reset, all existing tokens are invalidated (user must re-login with new password).

4. **Email Verification**: No email verification sent - user can immediately use email for password reset after adding it.

---

## 8. Testing Checklist

### Password Reset (Parents)
- [ ] Request reset with valid email → Email received with 6-digit code
- [ ] Request reset with non-existent email → Still shows "Check your email"
- [ ] Request reset with child account email → Still shows "Check your email"
- [ ] Reset with valid code → Success, can login with new password
- [ ] Reset with expired code → "Invalid or expired code" error
- [ ] Reset with used code → "Code already used" error
- [ ] Old tokens invalidated after reset → 401 on next API call

### Child Password Reset (Parent-Initiated)
- [ ] Parent resets child password → Success
- [ ] Child logs in with new password → Success
- [ ] Non-parent tries to reset → 403 forbidden

### Email Management
- [ ] Parent registration without email → 400 validation_error
- [ ] Parent registration with email → Saved in profile
- [ ] Child registration with email → 400 validation_error
- [ ] Update email in settings → Updated successfully
- [ ] Duplicate email check → 409 conflict error
- [ ] Invalid email format → 400 validation_error
- [ ] Child cannot update email in settings → 400 validation_error

### Rewards
- [ ] Child creates reward without memberId → Defaults to self
- [ ] Child tries to create for sibling → 403 forbidden
- [ ] Parent creates reward for child → Success

---

## 9. Environment Variables Required

Backend requires these environment variables:
- `SENDGRID_API_KEY` - For sending password reset emails via SendGrid
- `JWT_SECRET` - Existing, used for token signing

No iOS-side configuration needed.