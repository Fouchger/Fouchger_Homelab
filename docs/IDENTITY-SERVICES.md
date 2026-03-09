# Identity Services

## Purpose
This document records the current identity platform direction for the homelab.

## Service split
### OpenBao
- Secrets storage
- Bootstrap material
- Token and credential brokering

### authentik
- Application SSO
- OIDC, SAML, LDAP-style integrations, and proxy patterns
- Primary target for app-facing authentication

### FreeIPA
- Linux users and groups
- Central sudo policy
- SSH key distribution
- Host-based access control
- Optional integrated DNS and certificate workflows

## Recommended rollout order
1. Keep OpenBao as the secrets anchor.
2. Deploy authentik for application SSO.
3. Add FreeIPA when central Linux identity becomes operationally useful.

## Automation notes
- authentik installation and configuration support automated deployment workflows through environment-driven installation and provider-based configuration. citeturn0search0turn0search9turn0search12
- FreeIPA server and client deployment are supported by the upstream `ansible-freeipa` project. citeturn0search1turn0search4turn0search16
