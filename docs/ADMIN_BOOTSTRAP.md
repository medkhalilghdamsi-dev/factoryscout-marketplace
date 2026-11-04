# First FactoryScout admin — bootstrap status

**Current live status (2026-11-04):** Supabase has 1 Auth user, 1 profile and 1 profile with the `admin` role. The initial owner bootstrap is complete. Do not run `supabase/bootstrap_first_admin.sql` again for this project.

## For future recovery or a new environment

The bootstrap script is a guarded, one-time owner operation. Only use it in a fresh environment after confirming there is no existing administrator.

1. Create an account using the intended owner's email through the FactoryScout account portal.
2. Confirm the email address and sign in once so the profile trigger can create the profile.
3. Open the Supabase project SQL Editor as the project owner.
4. Open `supabase/bootstrap_first_admin.sql`, replace `REPLACE_WITH_OWNER_EMAIL` with the exact email used at signup, and run it once only if the environment has no existing admin.
5. Sign out and back in to refresh the profile/role, then verify that the Admin moderation dashboard appears.

## Security properties

- There is no public admin signup, endpoint, or client-side role promotion.
- The SQL script refuses to run if an admin already exists.
- It requires a pre-existing Supabase Auth user and updates only that user's profile role.
- Keep the script private to project administrators; do not add the owner's email to public application code.
- Never rerun the bootstrap in an environment that already has an admin.
