const libs = {
  portal: require("/lib/xp/portal"),
  freemarker: require("/site/lib/tineikt/freemarker")
};
const view = resolve("default.ftl");

exports.get = () => {
  const content = libs.portal.getContent();

  const isFragment = content.type === "portal:fragment";

  const model = {
    isFragment,
    regions: isFragment ? null : content.page.regions.main
  };

  return {
    body: libs.freemarker.render(view, model)
  };
};
