/**
 * Constants in this module will be replaced by webpack.DefinePlugin.
 * We declare them globally (vs. importing), because it is important
 * that Webpack can inline and eliminate things.
 */
declare const NOW_GITHUB_COMMIT_SHA: string;
