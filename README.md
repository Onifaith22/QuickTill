# QuickTill

QuickTill is a simple web-based checkout application built for the Group 6 Cloud & DevOps Bootcamp capstone project.

The application allows users to browse available products, add items to a shopping basket, adjust quantities, view the order total, and simulate a checkout.

## Technologies Used

**Frontend**
- React
- Vite
- JavaScript
- CSS

**Backend**
- Node.js
- Express.js

## Project Structure

```text
QuickTill/
├── frontend/    # React + Vite application
├── backend/     # Express API
└── README.md
```

## Prerequisites

Before running the application, ensure you have installed:

- Node.js (LTS recommended)
- npm
- Git

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Onifaith22/QuickTill.git
cd QuickTill
```

### 2. Set up the backend

Open a terminal and navigate to the backend directory:

```bash
cd backend
npm install
```

Start the backend server:

```bash
node server.js
```

The API runs at:

`http://localhost:5000`

### 3. Set up the frontend

Open a second terminal and navigate to the frontend directory:

```bash
cd QuickTill/frontend
npm install
```

Start the development server:

```bash
npm run dev
```

Open the application in your browser:

`http://localhost:5173`

**Important:** Keep both the frontend and backend servers running while using the application.

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Checks API health |
| GET | `/version` | Returns application version |
| POST | `/api/checkout` | Processes a simulated checkout |

## Checkout

QuickTill currently supports simulated checkout. It validates the submitted basket and calculates the order total.

No real payment processing or database integration is currently implemented.

## Contributing

Team members are welcome to explore, test, and suggest improvements to QuickTill.

1. Fork or clone the repository.
2. Make changes on your own copy or branch.
3. Test your changes locally.
4. Submit a pull request for review.

The main repository is maintained centrally to keep the project consistent.

## Project Context

QuickTill is the application used by Group 6 for the **Zero-Downtime Blue-Green Deployment** capstone project.

Docker, Azure App Service deployment slots, GitHub Actions, health-check gates, and rollback procedures are described under [Deployment](#deployment).

## Deployment

Every push to `main` goes through this pipeline:

1. **CI** (`ci.yml`) lints, builds and runs the health gate against local containers.
2. **CD** (`cd.yml`) starts only if CI passed:
   - builds and pushes both images to Docker Hub (`docker-build.yml`), tagged with the short commit SHA, plus `latest` for the backend and `v2` for the frontend
   - deploys the SHA-tagged images to the **staging** slots (Green)
   - runs `scripts/health-check.sh` against staging. If any check fails, the run stops and production is not touched
   - swaps staging into production (Blue)
   - runs the health gate against production, and swaps back automatically if it fails

The backend's `/version` and the frontend's `/version.txt` show which build is live.

### Rollback

After every deploy, the staging slots still hold the previous production build.

- **Automatic:** if the production health gate fails right after a swap, CD swaps back.
- **Manual:** go to Actions → **Rollback** → Run workflow. It swaps staging back into production and runs the health gate. Run it once per bad deploy, because running it again swaps the bad build back in.
- **An older build:** every build stays on Docker Hub under its SHA tag. Point the staging slot at it, check it, then swap (same for the frontend with `app-quicktill-web-ioprww`):

  ```bash
  az webapp config container set -g rg-quicktill -n app-quicktill-ioprww -s staging \
    --container-image-name onifaith22/quicktill-backend:<sha>
  bash scripts/health-check.sh https://app-quicktill-ioprww-staging.azurewebsites.net
  az webapp deployment slot swap -g rg-quicktill -n app-quicktill-ioprww --slot staging --target-slot production
  ```

### Setup

- Repository variable `DOCKERHUB_USERNAME` and secret `DOCKERHUB_TOKEN`
- Secret `AZURE_CREDENTIALS`: lets GitHub Actions sign in to Azure. It is a service principal limited to `rg-quicktill` with the Website Contributor role, which can change the web apps' images and swap slots but nothing else. Created by someone with access to the Azure subscription:

  ```bash
  az ad sp create-for-rbac --name quicktill-github --role "Website Contributor" \
    --scopes /subscriptions/<subscription-id>/resourceGroups/rg-quicktill --json-auth
  ```

  The JSON it prints is pasted as the secret's value.