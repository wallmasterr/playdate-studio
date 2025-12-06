import { remove, writeFile, ensureDir } from "fs-extra";
import Path from "path";
import AdmZip from "adm-zip";
import spawn from "../../src/lib/helpers/cli/spawn";
import https from "https";
import { URL } from "url";

const buildToolsRoot = Path.join(
  Path.normalize(`${__dirname}/../../`),
  "buildTools",
);

const dependencies = {
  "darwin-arm64": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-macos-arm64.tar.gz",
      type: "targz",
    },
  },
  "darwin-x64": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-macos.tar.gz",
      type: "targz",
    },
  },
  "linux-x64": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-linux64.tar.gz",
      type: "targz",
    },
  },
  "linux-arm64": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-linux-arm64.tar.gz",
      type: "targz",
    },
  },
  "win32-ia32": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-win32.zip",
      type: "zip",
    },
  },
  "win32-x64": {
    gbdk: {
      url: "https://github.com/gbdk-2020/gbdk-2020/releases/download/gbdk-next/gbdk-win64.zip",
      type: "zip",
    },
  },
} as const;

type Arch = keyof typeof dependencies;

const archs = Object.keys(dependencies) as Array<Arch>;
const localArch = `${process.platform}-${process.arch}`;

const fetchAll = process.argv.includes("--all");
const fetchArch =
  process.argv
    .find((arg) => arg.startsWith("--arch="))
    ?.replace("--arch=", "") ?? localArch;

const extractTarGz = async (
  archivePath: string,
  outputDir: string,
): Promise<void> => {
  console.log(`Extract tar to "${outputDir}"`);
  const res = spawn("tar", ["-zxf", archivePath, "-C", outputDir], {}, {});
  await res.completed;
  console.log("✅ Done");
};

const extractZip = async (
  archivePath: string,
  outputDir: string,
): Promise<void> => {
  console.log(`Extract zip to "${outputDir}"`);
  const zip = new AdmZip(archivePath);
  await zip.extractAllTo(outputDir, true);
  console.log("✅ Done");
};

export const fetchGBDKDependency = async (arch: Arch) => {
  console.log(`Fetching GBDK for arch=${arch}`);
  const { url, type } = dependencies[arch].gbdk;
  console.log(`URL=${url}`);

  // Use Node's built-in https module for Node.js 16 compatibility
  const fetchWithRedirects = async (urlToFetch: string): Promise<Buffer> => {
    return new Promise<Buffer>((resolve, reject) => {
      const urlObj = new URL(urlToFetch);
      const options = {
        hostname: urlObj.hostname,
        path: urlObj.pathname + urlObj.search,
        headers: {
          "User-Agent": "GB-Studio",
        },
      };

      https
        .get(options, (res) => {
          // Follow redirects (301, 302, 307, 308)
          if (
            res.statusCode &&
            [301, 302, 307, 308].includes(res.statusCode) &&
            res.headers.location
          ) {
            res.destroy();
            // Recursively follow redirect
            fetchWithRedirects(res.headers.location)
              .then(resolve)
              .catch(reject);
            return;
          }

          if (res.statusCode !== 200) {
            reject(
              new Error(
                `Failed to fetch ${urlToFetch}: ${res.statusCode} ${res.statusMessage}`
              )
            );
            return;
          }

          const chunks: Buffer[] = [];
          res.on("data", (chunk: Buffer) => chunks.push(chunk));
          res.on("end", () => resolve(Buffer.concat(chunks)));
          res.on("error", reject);
        })
        .on("error", reject);
    });
  };

  const data = await fetchWithRedirects(url);
  const tmpPath = Path.join(buildToolsRoot, "tmp.data");
  await writeFile(tmpPath, data);
  console.log(`Written to "${tmpPath}"`);

  const gbdkArchPath = Path.join(buildToolsRoot, arch);
  await ensureDir(gbdkArchPath);

  if (type === "targz") {
    await extractTarGz(tmpPath, gbdkArchPath);
  } else {
    await extractZip(tmpPath, gbdkArchPath);
  }

  await remove(tmpPath);
};

const main = async () => {
  await ensureDir(buildToolsRoot);
  for (const arch of archs) {
    if (fetchAll || arch === fetchArch) {
      await fetchGBDKDependency(arch);
    }
  }
};

main().catch((e) => {
  console.error(`❌ Error: `, e);
});
