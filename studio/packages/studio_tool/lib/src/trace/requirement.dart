/// A requirement of the SRS that a test may verify.
///
/// `increment` is the first increment in which the requirement enters,
/// such as `F1`, and `isTested` tells whether its verification method
/// includes an automated test.
typedef Requirement = ({String id, String increment, bool isTested});
