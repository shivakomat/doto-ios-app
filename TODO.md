# Doto TODO (later)

## Subscriptions / RevenueCat
- [ ] Configure the RevenueCat webhook (Integrations -> Webhooks) to `https://doto-api-5e3a07135be3.herokuapp.com/api/webhooks/revenuecat`. No real purchase has ever reached the backend.
- [ ] Set `REVENUECAT_SECRET_KEY` on Heroku (`heroku config:set REVENUECAT_SECRET_KEY=<value> --app doto-api`) so the webhook rejects unsigned requests. Currently unset, so anyone can POST a fake purchase event.
- [ ] Confirm which header RevenueCat sends. The backend checks `X-RevenueCat-Signature`; RevenueCat's webhook auth may use an `Authorization` header instead. Verify against their docs and adjust `isSignatureValid`.
- [ ] Check the product is attached to an entitlement in RevenueCat (likely cause of the paywall staying stuck after purchase).
- [ ] Families without a subscription row (e.g. Okon) hit 402s on premium endpoints once the 14-day server trial ends.

## Cleanup
- [ ] Delete unused files: `Doto/Schedule/DayView.swift`, `Doto/Auth/AuthView.swift`, `Doto/Shared/Components/DotoNavHeader.swift`.
- [ ] Remove stale small icon files in `AppIcon.appiconset` (causes an "unassigned children" build warning).
- [ ] Optional: new evolution in doto-api so fresh databases get the `Demo123!` demo password and the Jobs family demo subscription.
