# Form States and Flow

Depending on the submission and the messages coming in, the Form can be in one of many states.
This started because some parts of the flow use Commands, which cannot be chained:
- Getting the time (A task, but chaining the rest is not possible, so it might as well return Cmd)
- Getting the location (Ports)
- Getting the "entry saved" confirmation

This is a good prompt to model the form state explicitly, instead of accidentally having it change whenever!

Here are the states and transitions:
- Untouched
- Input (user types in)
- AwaitingTime (show loading)
    - TimeError?
- AwaitingLocation (show loading)
    - LocationError
- Submitting / WaitingForConfirmation (show loading)
  - SubmittedOk (clear fields, announce success)
  - SubmittedError (keep fields announce error)
