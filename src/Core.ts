/** JS and JSON representations of elm's core data structures.
 * Used to encourage type-safety on both sides of the port boundary,
 * as well as to standardise encoding/decoding in the codebase.
 */
export {Maybe, Maybe_Nothing, Maybe_Just, Result, Result_Ok, Result_Error};

// Maybe

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

// Result

type Result<Error, Data> = {tag: 'Ok'; data: Data} | {tag: 'Err'; data: Error};

const Result_Ok = <A>(data: A): Result<any, A> => ({tag: 'Ok', data});

const Result_Error = <E>(data: E): Result<E, any> => ({
  tag: 'Err',
  data,
});
