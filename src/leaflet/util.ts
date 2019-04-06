/** Return a StyleSheet, or the argument text, depending on support for Constructable StyleSheet. */
export const getStyleResult = (styleText: string) => {
  if ('adoptedStyleSheets' in document) {
    const sheet = new CSSStyleSheet();
    return {
      sheet,
      text: null,
    };
  } else {
    return {
      sheet: null,
      text: styleText,
    };
  }
};
