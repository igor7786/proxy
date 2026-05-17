###
1. Create an Application in Authentik:

Go to Applications → Applications → Create
Name: Redis Insight
Slug: redis-insight
Leave provider empty for now → Save

2. Create a Proxy Provider:

Go to Applications → Providers → Create
Choose Proxy Provider
Name: Redis Insight
Authentication flow: default-authentication-flow
Authorization flow: default-provider-authorization-explisit-consent
Mode: Forward auth (single application)
External host: https://redis-insight.fast-web-tech.co.uk
Save

3. Link Provider to Application:

Go back to your Redis Insight application
Edit it → set Provider to Redis Insight
Save

4. In NPMplus:

Edit redis-insight.fast-web-tech.co.uk proxy host
Scroll to Auth Request dropdown
Select authentik
Save

Then test by opening https://redis-insight.fast-web-tech.co.uk — it should redirect to Authentik login page.

GitHub:

Go to GitHub → Settings → Developer settings → OAuth Apps → New OAuth App
Set callback URL to https://auth.fast-web-tech.co.uk/source/oauth/callback/github/
Copy Client ID and Secret
In Authentik → Directory → Federation & Social login → Add → GitHub

Google:

Go to Google Cloud Console → APIs & Services → Credentials → Create OAuth 2.0 Client
Set callback URL to https://auth.fast-web-tech.co.uk/source/oauth/callback/google/
Copy Client ID and Secret
In Authentik → Directory → Federation & Social login → Add → Google

Because you need to add the GitHub source to your authentication flow. Go to:

Flows → default-authentication-flow → click on it
Stage Bindings → find the default-authentication-identification stage → click edit (pencil icon)
Scroll down to Sources
Add GitHub to the sources list
Save
