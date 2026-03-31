# LTI 1.3 Tool Provider (POC) – CircuitVerse GSoC 2026

## Overview

This project implements a **minimal LTI 1.3 Tool Provider** using Ruby on Rails as part of the CircuitVerse GSoC 2026 assignment.

It demonstrates a complete **OIDC-based LTI launch flow**, where an LMS (simulated using saLTIre) launches the tool and sends a signed `id_token` (JWT), which is decoded and displayed.

While implementing this, I ran into issues with redirect_uri mismatch and OIDC parameter handling in saLTIre, which I resolved by adjusting the login flow and ensuring exact URL matching.
---

## Features

* LTI 1.3 OIDC Login Initiation
* Launch Callback handling
* JWKS endpoint for tool public keys
* JWT decoding and claim extraction
* Display of user, course, and role information
* Compatible with saLTIre platform emulator

---

## Tech Stack

* Ruby on Rails
* JWT (`ruby-jwt`)
* OpenSSL (for JWKS generation)
* ngrok (for HTTPS tunneling)

---

## Endpoints

### 1. `/jwks.json`

* Returns the tool’s public key (JWKS format)
* Used by LMS for verifying signatures (in real implementation)

---

### 2. `/lti/oidc/login`

* Handles OIDC login initiation
* Receives:

  * `iss`
  * `login_hint`
  * `target_link_uri`
  * `lti_message_hint`
* Generates:

  * `state`
  * `nonce`
* Redirects to LMS authorization endpoint

---

### 3. `/lti/oidc/callback`

* Receives:

  * `id_token` (JWT)
  * `state`
* Decodes JWT (without signature verification in this POC)
* Extracts and displays LTI claims:

  * user info
  * roles
  * course context

---

## LTI 1.3 Flow

1. LMS → `/lti/oidc/login`
2. Tool generates `state` and `nonce`
3. Tool redirects to LMS auth endpoint
4. LMS → `/lti/oidc/callback` with `id_token`
5. Tool decodes JWT and displays claims

---

## Setup Instructions

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd <repo-name>
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Run server

```bash
bundle exec rails server
```

### 4. Start ngrok

```bash
ngrok http 3000
```

---

## Testing with saLTIre

1. Go to: https://saltire.lti.app/platform

2. Configure tool:

   * **OIDC Login URL**

     ```
     https://<ngrok-url>/lti/oidc/login
     ```
   * **Redirect URL**

     ```
     https://<ngrok-url>/lti/oidc/callback
     ```
   * **JWKS URL**

     ```
     https://<ngrok-url>/jwks.json
     ```

3. Register tool and launch

---

## Screenshots

* saLTIre configuration
<img width="1913" height="872" alt="Screenshot 2026-03-31 200140" src="https://github.com/user-attachments/assets/9a646a68-2124-4101-86e1-85858c9641cb" />

* Successful launch
  <img width="931" height="978" alt="Screenshot 2026-03-31 200203" src="https://github.com/user-attachments/assets/0928a0ef-7d79-4b8e-b8e2-ff44c28da032" />
---

## Conclusion

This project successfully demonstrates a working **LTI 1.3 OIDC launch flow** and serves as a foundation for integrating modern LMS capabilities into CircuitVerse.

---
👤 Author
Name:Nisshchaya Rathi
Contact: nisshchayarathi@gmail.com
