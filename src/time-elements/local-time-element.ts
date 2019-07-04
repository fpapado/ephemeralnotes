/* Adapted from: https://github.com/github/time-elements.
  Original license (MIT) follows:

  Copyright (c) 2014-2018 GitHub, Inc.
  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
import {strftime, makeFormatter, isDayFirst} from './utils';

const formatters = new WeakMap();

export class LocalTimeElement extends HTMLElement {
  _date?: Date;

  static get observedAttributes() {
    return [
      'datetime',
      'day',
      'format',
      'hour',
      'minute',
      'month',
      'second',
      'title',
      'weekday',
      'year',
    ];
  }

  connectedCallback() {
    this.setTitleAndText();
  }

  // Internal: Refresh the time element's formatted date when an attribute changes.
  attributeChangedCallback(
    attrName: string,
    oldValue: string,
    newValue: string
  ) {
    if (
      attrName === 'hour' ||
      attrName === 'minute' ||
      attrName === 'second' ||
      attrName === 'time-zone-name'
    ) {
      formatters.delete(this);
    }
    if (attrName === 'datetime') {
      const millis = Date.parse(newValue);
      this._date = isNaN(millis) ? undefined : new Date(millis);
    }
    this.setTitleAndText();
  }

  setTitleAndText() {
    const title = this.getFormattedTitle();
    if (title && !this.hasAttribute('title')) {
      this.setAttribute('title', title);
    }

    const text = this.getFormattedDate();

    if (text) {
      this.textContent = text;
    }
  }

  // Internal: Format the ISO 8601 timestamp according to the user agent's
  // locale-aware formatting rules. The element's existing `title` attribute
  // value takes precedence over this custom format.
  //
  // Returns a formatted time String.
  getFormattedTitle(): string | undefined {
    const date = this._date;
    if (!date) return;

    const formatter = titleFormatter();
    if (formatter) {
      return formatter.format(date);
    } else {
      try {
        return date.toLocaleString();
      } catch (e) {
        if (e instanceof RangeError) {
          return date.toString();
        } else {
          throw e;
        }
      }
    }
  }

  // Formats the element's date, in the user's current locale, according to
  // the formatting attribute values. Values are not passed straight through to
  // an Intl.DateTimeFormat instance so that weekday and month names are always
  // displayed in English, for now.
  //
  // Supported attributes are:
  //
  //   weekday - "short", "long"
  //   year    - "numeric", "2-digit"
  //   month   - "short", "long"
  //   day     - "numeric", "2-digit"
  //   hour    - "numeric", "2-digit"
  //   minute  - "numeric", "2-digit"
  //   second  - "numeric", "2-digit"
  //
  // Returns a formatted time String.
  getFormattedDate(): string | undefined {
    const d = this._date;
    if (!d) return;

    const date = formatDate(this, d) || '';
    const time = formatTime(this, d) || '';
    return `${date} ${time}`.trim();
  }
}

// Private: Format a date according to the `weekday`, `day`, `month`,
// and `year` attribute values.
//
// This doesn't use Intl.DateTimeFormat to avoid creating text in the user's
// language when the majority of the surrounding text is in English. There's
// currently no way to separate the language from the format in Intl.
//
// el - The local-time element to format.
//
// Returns a date String or null if no date formats are provided.
function formatDate(el: Element, date: Date) {
  // map attribute values to strftime
  const props = {
    weekday: {
      short: '%a',
      long: '%A',
    },
    day: {
      numeric: '%e',
      '2-digit': '%d',
    },
    month: {
      short: '%b',
      long: '%B',
    },
    year: {
      numeric: '%Y',
      '2-digit': '%y',
    },
  };

  // build a strftime format string
  let format = isDayFirst()
    ? 'weekday day month year'
    : 'weekday month day, year';
  for (const prop in props) {
    // @ts-ignore
    const value = props[prop][el.getAttribute(prop)];
    format = format.replace(prop, value || '');
  }

  // clean up year separator comma
  format = format.replace(/(\s,)|(,\s$)/, '');

  // squeeze spaces from final string
  return strftime(date, format)
    .replace(/\s+/, ' ')
    .trim();
}

// Private: Format a time according to the `hour`, `minute`, and `second`
// attribute values.
//
// el - The local-time element to format.
//
// Returns a time String or null if no time formats are provided.
function formatTime(el: Element, date: Date) {
  const options: Intl.DateTimeFormatOptions = {};

  // retrieve format settings from attributes
  const hour = el.getAttribute('hour');
  if (hour === 'numeric' || hour === '2-digit') options.hour = hour;
  const minute = el.getAttribute('minute');
  if (minute === 'numeric' || minute === '2-digit') options.minute = minute;
  const second = el.getAttribute('second');
  if (second === 'numeric' || second === '2-digit') options.second = second;
  const tz = el.getAttribute('time-zone-name');
  if (tz === 'short' || tz === 'long') options.timeZoneName = tz;

  // No time format attributes provided.
  if (Object.keys(options).length === 0) {
    return;
  }

  let factory = formatters.get(el);
  if (!factory) {
    factory = makeFormatter(options);
    formatters.set(el, factory);
  }

  const formatter = factory();
  if (formatter) {
    // locale-aware formatting of 24 or 12 hour times
    return formatter.format(date);
  } else {
    // fall back to strftime for non-Intl browsers
    const timef = options.second ? '%H:%M:%S' : '%H:%M';
    return strftime(date, timef);
  }
}

const titleFormatter = makeFormatter({
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
  timeZoneName: 'short',
});

// Public: LocalTimeElement constructor.
//
//   var time = new LocalTimeElement()
//   # => <local-time></local-time>
//
export const define = () =>
  window.customElements.define('local-time', LocalTimeElement);
