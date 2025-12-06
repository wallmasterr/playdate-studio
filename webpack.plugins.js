/* eslint-disable @typescript-eslint/no-var-requires */
const webpack = require("webpack");
const ForkTsCheckerWebpackPlugin = require("fork-ts-checker-webpack-plugin");
const BundleAnalyzerPlugin =
  require("webpack-bundle-analyzer").BundleAnalyzerPlugin;
const { GitRevisionPlugin } = require("git-revision-webpack-plugin");
const pkg = require("./package.json");

const gitRevisionPlugin = new GitRevisionPlugin({
  commithashCommand: "rev-list --max-count=1 --no-merges --abbrev-commit HEAD",
});

const docsUrl = "https://www.gbstudio.dev/docs/";

const plugins = [
  new webpack.DefinePlugin({
    GIT_VERSION: JSON.stringify(gitRevisionPlugin.version()),
    COMMITHASH: JSON.stringify(gitRevisionPlugin.commithash()),
    VERSION: JSON.stringify(pkg.version),
    DOCS_URL: JSON.stringify(docsUrl),
  }),
];

if (process.env.ANALYZE_BUNDLE) {
  plugins.push(new BundleAnalyzerPlugin());
}

if (!process.env.NO_TYPE_CHECKING) {
  // During production builds, exclude test files to avoid type errors
  // that don't affect the actual application build
  const isProduction = process.env.NODE_ENV === "production";
  plugins.push(
    new ForkTsCheckerWebpackPlugin({
      async: false,
      typescript: {
        memoryLimit: 4096,
        // Use build config that excludes test files in production
        configFile: isProduction 
          ? require("path").join(__dirname, "tsconfig.build.json")
          : undefined,
      },
    })
  );
}

module.exports = plugins;
