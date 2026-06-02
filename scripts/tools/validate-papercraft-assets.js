const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..", "..");
const ASSET_ROOT = "assets/papercraft";
const MANIFEST_ROOT = path.join(ROOT, ASSET_ROOT, "manifests");

const REQUIRED_DIRECTORIES = [
  "assets/papercraft/core/references",
  "assets/papercraft/core/materials",
  "assets/papercraft/core/ui",
  "assets/papercraft/fragments/id0762/environment",
  "assets/papercraft/fragments/id0762/characters",
  "assets/papercraft/fragments/id0762/props",
  "assets/papercraft/fragments/id0762/fx",
  "assets/papercraft/manifests",
];

const CATEGORIES = new Set([
  "reference",
  "material",
  "ui",
  "environment",
  "character",
  "prop",
  "fx",
  "mask",
]);
const STATUSES = new Set(["planned", "candidate", "review", "ready"]);
const GENERATION_MODES = new Set([
  "reference_board",
  "reference_edit",
  "isolated_asset",
  "ui_component",
  "effect_composite",
  "manual_mask",
]);
const MILESTONES = new Set([
  "golden_reference",
  "vertical_slice",
  "id0762_full",
  "global_ui",
]);

const errors = [];
const ids = new Set();
const assetsById = new Map();

function fail(message) {
  errors.push(message);
}

function checkDirectory(relativePath) {
  if (!fs.existsSync(path.join(ROOT, relativePath))) {
    fail(`missing directory: ${relativePath}`);
  }
}

function validateAsset(asset, manifestName, index) {
  const prefix = `${manifestName} assets[${index}]`;
  const required = ["id", "path", "category", "role", "status", "generation", "requiredFor"];
  for (const field of required) {
    if (!asset[field]) {
      fail(`${prefix}: missing ${field}`);
    }
  }
  if (!asset.id || !/^[a-z0-9_]+$/.test(asset.id)) {
    fail(`${prefix}: id must use lowercase letters, digits, and underscores`);
  } else if (ids.has(asset.id)) {
    fail(`${prefix}: duplicate id ${asset.id}`);
  } else {
    ids.add(asset.id);
    assetsById.set(asset.id, asset);
  }
  if (!asset.path || !asset.path.startsWith(`${ASSET_ROOT}/`) || asset.path.includes("..")) {
    fail(`${prefix}: path must stay under ${ASSET_ROOT}/`);
  }
  if (!CATEGORIES.has(asset.category)) {
    fail(`${prefix}: unsupported category ${asset.category}`);
  }
  if (!STATUSES.has(asset.status)) {
    fail(`${prefix}: unsupported status ${asset.status}`);
  }
  if (!GENERATION_MODES.has(asset.generation)) {
    fail(`${prefix}: unsupported generation mode ${asset.generation}`);
  }
  if (!MILESTONES.has(asset.requiredFor)) {
    fail(`${prefix}: unsupported milestone ${asset.requiredFor}`);
  }
  if (asset.path && !asset.path.endsWith(".png")) {
    fail(`${prefix}: formal asset path must end with .png`);
  }
  if (asset.status && asset.status !== "planned" && asset.path) {
    if (!fs.existsSync(path.join(ROOT, asset.path))) {
      fail(`${prefix}: ${asset.status} asset file does not exist: ${asset.path}`);
    }
  }
}

for (const directory of REQUIRED_DIRECTORIES) {
  checkDirectory(directory);
}

if (!fs.existsSync(MANIFEST_ROOT)) {
  fail(`missing manifest root: ${ASSET_ROOT}/manifests`);
} else {
  const manifestFiles = fs.readdirSync(MANIFEST_ROOT).filter((name) => name.endsWith(".json")).sort();
  if (manifestFiles.length === 0) {
    fail("no papercraft manifests found");
  }
  for (const manifestName of manifestFiles) {
    const manifestPath = path.join(MANIFEST_ROOT, manifestName);
    let manifest;
    try {
      manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    } catch (error) {
      fail(`${manifestName}: invalid JSON: ${error.message}`);
      continue;
    }
    if (manifest.schemaVersion !== 1) {
      fail(`${manifestName}: schemaVersion must be 1`);
    }
    if (!manifest.scope || typeof manifest.scope !== "string") {
      fail(`${manifestName}: scope must be a non-empty string`);
    }
    if (!Array.isArray(manifest.assets)) {
      fail(`${manifestName}: assets must be an array`);
      continue;
    }
    manifest.assets.forEach((asset, index) => validateAsset(asset, manifestName, index));
  }
}

for (const asset of assetsById.values()) {
  if (asset.maskFor && !assetsById.has(asset.maskFor)) {
    fail(`${asset.id}: maskFor target does not exist: ${asset.maskFor}`);
  }
  if (asset.category === "mask" && !asset.maskFor) {
    fail(`${asset.id}: mask assets must define maskFor`);
  }
}

if (errors.length > 0) {
  console.error("[papercraft] validation failed");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(`[papercraft] validation passed: ${assetsById.size} planned assets across manifests`);
