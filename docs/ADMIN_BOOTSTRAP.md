# First FactoryScout admin — one-time bootstrap

The live Supabase project currently has **zero Auth users, zero profiles and zero admins**. Supplier applications can be submitted, but nobody can review or approve them until the owner account is created and promoted.

## Required owner action

1. Open [FactoryScout](https://factoryscout-marketplace.onrender.com/).
2. Open the account portal and create an account using the owner's email. Choose a buyer account; the bootstrap script changes only the privileged `role`.
3. Confirm the email address and sign in once so the profile trigger can create the profile.
4. Open the Supabase project SQL Editor as the project owner.
5. Open `supabase/bootstrap_first_admin.sql`, replace `REPLACE_WITH_OWNER_EMAIL` with the exact email used at signup, and run it once.
6. Sign out and back in to refresh the profile/role, then verify that the Admin moderation dashboard appears.

## Security properties

- There is no public admin signup, endpoint, or client-side role promotion.
- The SQL script refuses to run if an admin already exists.
- It requires a pre-existing Supabase Auth user and updates only that user's profile role.
- Keep the script private to project administrators; do not add the owner's email to public application code.
- If the owner account is not created first, the script fails safely.

This is intentionally a manual owner-only step. The project currently has no Auth users, so promoting an account before the owner signs up is impossible and would be unsafe to fake.
