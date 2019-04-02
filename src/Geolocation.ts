/* Typed Geolocation acquisition and callback
 * Adapted for usage with Ports from https://github.com/elm-lang/geolocation
 * The encoding of tag/data for data structures is standard in this
 * code base, but there is nothing special about it.
 */

// TODO: Movev this to a module
type Maybe<Data> = {
  tag: 'Maybe';
  data: {tag: 'Just'; data: Data} | {tag: 'Nothing'};
};
const Maybe_Nothing = (): Maybe<any> => ({
  tag: 'Maybe',
  data: {tag: 'Nothing'},
});
const Maybe_Just = <A>(data: A): Maybe<A> => ({
  tag: 'Maybe',
  data: {tag: 'Just', data},
});

export type Result<Error, Data> =
  | {tag: 'Ok'; data: Data}
  | {tag: 'Err'; data: Error};
export const Result_Ok = <A>(data: A): Result<any, A> => ({tag: 'Ok', data});
export const Result_Error = <E>(data: E): Result<E, any> => ({
  tag: 'Err',
  data,
});

// LOCATIONS

export type Location = ReturnType<typeof toLocation>;
export type LocationError = ReturnType<typeof toError>;

function toLocation(rawPosition: Position) {
  var coords = rawPosition.coords;

  var rawAltitude = coords.altitude;
  var rawAccuracy = coords.altitudeAccuracy;
  var altitude: Maybe<number> =
    rawAltitude === null || rawAccuracy === null
      ? Maybe_Nothing()
      : Maybe_Just({value: rawAltitude, accuracy: rawAccuracy});

  var heading = coords.heading;
  var speed = coords.speed;

  var movement =
    heading === null || speed === null
      ? Maybe_Nothing()
      : Maybe_Just(
          speed === 0
            ? {tag: 'Static'}
            : {
                tag: 'Moving',
                data: {__$speed: speed, __$degreesFromNorth: heading},
              }
        );

  return {
    lat: coords.latitude,
    lon: coords.longitude,
    accuracy: coords.accuracy,
    altitude,
    movement,
    timestamp: rawPosition.timestamp,
  };
}

// ERRORS
// @see https://developer.mozilla.org/en-US/docs/Web/API/PositionError for the
// possible errors

let GeolocationErrors = ['PermissionDenied', 'PositionUnavailable', 'Timeout'];

function toError(positionErr: PositionError) {
  return {
    tag: GeolocationErrors[positionErr.code - 1],
    data: positionErr.message,
  };
}

// OPTIONS

const defaultOptions = {
  enableHighAccuracy: false,
  timeout: 30000,
  maximumAge: 10000,
};

// GET LOCATION
type LocationCallback = (data: Result<LocationError, Location>) => void;

export function getLocation(cb: LocationCallback, opts = {}) {
  const options = {...defaultOptions, opts};

  function onSuccess(rawPosition: Position) {
    console.log('Got location ok');
    cb(Result_Ok(toLocation(rawPosition)));
  }

  function onError(rawError: PositionError) {
    console.log('Got location err');
    cb(Result_Error(toError(rawError)));
  }

  // Get the location or report an "unavailable" error
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(onSuccess, onError, options);
  } else {
    onError({code: 2, message: 'Geolocation unavailable.'} as any);
  }
}
