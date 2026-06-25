/*
  Dev-only utility: delete all users' /activities subcollection docs.

  Usage:
    1) Authenticate Firebase CLI once:
         firebase login
    2) Get OAuth access token:
         firebase auth:print-access-token
    3) Run:
         node tool/reset_dev_activities_firestore.js --project <dev-project-id> --token <oauth-access-token>

  Safety:
    - Intended for DEV/STAGING only.
    - Deletes only users/*/activities/* docs.
*/

const args = process.argv.slice(2);
const projectIndex = args.indexOf("--project");
const tokenIndex = args.indexOf("--token");

if (projectIndex === -1 || tokenIndex === -1 || !args[projectIndex + 1] || !args[tokenIndex + 1]) {
  console.error(
    "Usage: node tool/reset_dev_activities_firestore.js --project <dev-project-id> --token <oauth-access-token>",
  );
  process.exit(1);
}

const projectId = args[projectIndex + 1];
const accessToken = args[tokenIndex + 1];
const base = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

async function fetchJson(url) {
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`HTTP ${res.status} for ${url}\n${text}`);
  }
  return res.json();
}

async function deleteDoc(name) {
  const url = `https://firestore.googleapis.com/v1/${name}`;
  const res = await fetch(url, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Delete failed ${res.status} for ${name}\n${text}`);
  }
}

async function listUsers() {
  const users = [];
  let nextPageToken = "";
  do {
    const url = new URL(`${base}/users`);
    url.searchParams.set("pageSize", "300");
    if (nextPageToken) {
      url.searchParams.set("pageToken", nextPageToken);
    }
    const json = await fetchJson(url.toString());
    users.push(...(json.documents || []));
    nextPageToken = json.nextPageToken || "";
  } while (nextPageToken);
  return users;
}

async function listActivitiesForUser(userName) {
  const parts = userName.split("/");
  const uid = parts[parts.length - 1];
  const docs = [];
  let nextPageToken = "";
  do {
    const url = new URL(`${base}/users/${uid}/activities`);
    url.searchParams.set("pageSize", "500");
    if (nextPageToken) {
      url.searchParams.set("pageToken", nextPageToken);
    }
    const json = await fetchJson(url.toString());
    docs.push(...(json.documents || []));
    nextPageToken = json.nextPageToken || "";
  } while (nextPageToken);
  return docs;
}

async function main() {
  console.log(`Project: ${projectId}`);
  const users = await listUsers();
  console.log(`Users found: ${users.length}`);

  let deleted = 0;
  for (const u of users) {
    const acts = await listActivitiesForUser(u.name);
    for (const a of acts) {
      await deleteDoc(a.name);
      deleted += 1;
      if (deleted % 100 === 0) {
        console.log(`Deleted ${deleted} activities...`);
      }
    }
  }

  console.log(`Done. Deleted activities: ${deleted}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
