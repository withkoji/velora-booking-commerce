# VIVIA | VELORA Inc

Central repository for VIVIA Rentals and VELORA By SJ applications, integrations, automation, booking, payments, and operations.

## Projects

- **VIVIA Rentals** — rental and property operations
- **VELORA By SJ** — spa, wellness, provider, and guest booking marketplace

## Core integrations

Stripe, Square, HubSpot, Fillout, Airtable, Zite, and provider/guest notifications.

## VIVIA Rental Management Database

The operational database is maintained in the Zite **VIVIA Rental Management** workspace. The repository database baseline is stored under:

`database/`

- [Database documentation](database/README.md)
- [Repository path reference](database/REPOSITORY_PATH.md)

Requested external path reference: `withkoji.com`

## Website redirect

The `/repository` path redirects visitors to the VELORA By SJ application.

Target: https://velorabysj.zite.so

## Security

Never commit API keys, access tokens, webhook signing secrets, OAuth credentials, or other secrets. Use environment variables and platform secret storage.

## Structure

```
vivia/
velora/
api/
integrations/
web/
docs/
database/
repository/
```
