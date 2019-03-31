/* Typed Geolocation acquisition and callback
 * Adapted for usage with Ports from https://github.com/elm-lang/geolocation
 * The encoding of tag/data for data structures is standard in this
 * code base, but there is nothing special about it.
 */

// TODO: Movev this to a module
const Maybe_Nothing = {tag: 'Maybe', data: {tag: 'Nothing'}};
const Maybe_Just = data => ({tag: 'Maybe', data: {tag: 'Just', data}});

const Result_Ok = data => ({tag: 'Ok', data});
const Result_Error = data => ({tag: 'Err', data});

// LOCATIONS

function toLocation(rawPosition) {
  var coords = rawPosition.coords;

  var rawAltitude = coords.altitude;
  var rawAccuracy = coords.altitudeAccuracy;
  var altitude =
    rawAltitude === null || rawAccuracy === null
      ? Maybe_Nothing
      : Maybe_Just({value: rawAltitude, accuracy: rawAccuracy});

  var heading = coords.heading;
  var speed = coords.speed;

  var movement =
    heading === null || speed === null
      ? Maybe_Nothing
      : Maybe_Just(
          speed === 0
            ? {tag: 'Static'}
            : {
                tag: 'Moving',
                data: {__$speed: speed, __$degreesFromNorth: heading},
              }
        );

  return {
    latitude: coords.latitude,
    longitude: coords.longitude,
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

function toError(positionErr) {
  return {
    tag: GeolocationErrors[positionErr.code - 1],
    data: positionErr.message,
  };
}

// OPTIONS

const defaultOptions = {
  enableHighAccuracy: false,
  timeout: 30000,
  maximumAge: 400,
};

// GET LOCATION
export function getLocation(cb, opts = {}) {
  const options = {...defaultOptions, opts};

  function onSuccess(rawPosition) {
    cb(Result_Ok(toLocation(rawPosition)));
  }

  function onError(rawError) {
    cb(Result_Error(toError(rawError)));
  }

  // Get the location or report an "unavailable" error
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(onSuccess, onError, options);
  } else {
    onError({code: 2, message: 'Geolocation unavailable.'});
  }
}
