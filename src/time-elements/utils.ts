const weekdays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

function pad(num: string | number) {
  return `0${num}`.slice(-2);
}

export function strftime(time: Date, formatString: string): string {
  const day = time.getDay();
  const date = time.getDate();
  const month = time.getMonth();
  const year = time.getFullYear();
  const hour = time.getHours();
  const minute = time.getMinutes();
  const second = time.getSeconds();
  return formatString.replace(/%([%aAbBcdeHIlmMpPSwyYZz])/g, function(_arg) {
    let match;
    const modifier = _arg[1];
    switch (modifier) {
      case '%':
        return '%';
      case 'a':
        return weekdays[day].slice(0, 3);
      case 'A':
        return weekdays[day];
      case 'b':
        return months[month].slice(0, 3);
      case 'B':
        return months[month];
      case 'c':
        return time.toString();
      case 'd':
        return pad(date);
      case 'e':
        return String(date);
      case 'H':
        return pad(hour);
      case 'I':
        return pad(strftime(time, '%l'));
      case 'l':
        if (hour === 0 || hour === 12) {
          return String(12);
        } else {
          return String((hour + 12) % 12);
        }
      case 'm':
        return pad(month + 1);
      case 'M':
        return pad(minute);
      case 'p':
        if (hour > 11) {
          return 'PM';
        } else {
          return 'AM';
        }
      case 'P':
        if (hour > 11) {
          return 'pm';
        } else {
          return 'am';
        }
      case 'S':
        return pad(second);
      case 'w':
        return String(day);
      case 'y':
        return pad(year % 100);
      case 'Y':
        return String(year);
      case 'Z':
        match = time.toString().match(/\((\w+)\)$/);
        return match ? match[1] : '';
      case 'z':
        match = time.toString().match(/\w([+-]\d\d\d\d) /);
        return match ? match[1] : '';
    }
    return '';
  });
}

export function makeFormatter(
  options: Intl.DateTimeFormatOptions
): () => Intl.DateTimeFormat | undefined {
  let format: Intl.DateTimeFormat;
  return function() {
    if (format) return format;
    if ('Intl' in window) {
      try {
        format = new Intl.DateTimeFormat(undefined, options);
        return format;
      } catch (e) {
        if (!(e instanceof RangeError)) {
          throw e;
        }
      }
    }
  };
}

let dayFirst: boolean | null = null;
const dayFirstFormatter = makeFormatter({day: 'numeric', month: 'short'});

// Private: Determine if the day should be formatted before the month name in
// the user's current locale. For example, `9 Jun` for en-GB and `Jun 9`
// for en-US.
//
// Returns true if the day appears before the month.
export function isDayFirst(): boolean {
  if (dayFirst !== null) {
    return dayFirst;
  }

  const formatter = dayFirstFormatter();
  if (formatter) {
    const output = formatter.format(new Date(0));
    dayFirst = !!output.match(/^\d/);
    return dayFirst;
  } else {
    return false;
  }
}

let yearSeparator: boolean | null = null;
const yearFormatter = makeFormatter({
  day: 'numeric',
  month: 'short',
  year: 'numeric',
});

// Private: Determine if the year should be separated from the month and day
// with a comma. For example, `9 Jun 2014` in en-GB and `Jun 9, 2014` in en-US.
//
// Returns true if the date needs a separator.
export function isYearSeparator() {
  if (yearSeparator !== null) {
    return yearSeparator;
  }

  const formatter = yearFormatter();
  if (formatter) {
    const output = formatter.format(new Date(0));
    yearSeparator = !!output.match(/\d,/);
    return yearSeparator;
  } else {
    return true;
  }
}

// Private: Determine if the date occurs in the same year as today's date.
//
// date - The Date to test.
//
// Returns true if it's this year.
export function isThisYear(date: Date) {
  const now = new Date();
  return now.getUTCFullYear() === date.getUTCFullYear();
}
