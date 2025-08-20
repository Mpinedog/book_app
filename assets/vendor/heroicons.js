const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = plugin(function ({ matchComponents, theme }) {
  // Try deps (git dep layout) then node_modules (npm package)
  const candidates = [
    path.join(__dirname, "../../deps/heroicons/optimized"),
    path.join(__dirname, "../node_modules/heroicons"), // npm install heroicons
  ];
  const iconsRoot = candidates.find((p) => fs.existsSync(p));

  // If no icon source is present, do nothing (prevents ENOENT in Docker)
  if (!iconsRoot) {
    return;
  }

  // Map the subdirs depending on the layout detected
  // deps/heroicons/optimized/<size>/<style>
  // node_modules/heroicons/<size>/<style>
  const pathFor = (sub) =>
    fs.existsSync(path.join(iconsRoot, "optimized"))
      ? path.join(iconsRoot, "optimized", sub)
      : path.join(iconsRoot, sub);

  const variants = [
    ["", pathFor(path.join("24", "outline"))],
    ["-solid", pathFor(path.join("24", "solid"))],
    ["-mini", pathFor(path.join("20", "solid"))],
    ["-micro", pathFor(path.join("16", "solid"))],
  ];

  const values = {};
  for (const [suffix, dir] of variants) {
    if (!fs.existsSync(dir)) continue;
    for (const file of fs.readdirSync(dir)) {
      if (!file.endsWith(".svg")) continue;
      const name = path.basename(file, ".svg") + suffix;
      values[name] = { name, fullPath: path.join(dir, file) };
    }
  }

  // If still nothing found, bail quietly
  if (Object.keys(values).length === 0) return;

  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "");
        content = encodeURIComponent(content);

        let size = theme("spacing.6");
        if (name.endsWith("-mini")) size = theme("spacing.5");
        else if (name.endsWith("-micro")) size = theme("spacing.4");

        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          mask: `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: size,
          height: size,
        };
      },
    },
    { values }
  );
});
