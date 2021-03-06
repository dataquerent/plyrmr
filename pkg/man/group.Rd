\name{group}
\alias{group}
\alias{group.f}
\alias{gather}
\alias{ungroup}
\alias{is.grouped}
\alias{is.root}

\title{Control grouping of data sets}
\description{
A data set in \code{plyrmr} , as represented by a pipe, is always grouped in one way or another. This means  that every computation acting on a pipe, acts on a subset of the data at a time. By contolling the group definition, we can implement complex algorithms while never loading all data into main memory, which wouldn't be feasible. The functions documented here allow to do that in \code{\link{plyrmr}}.
}
\usage{
group(.data, \dots, .recursive = FALSE, .envir = parent.frame())
group.f(.data, .f, \dots, .recursive = FALSE)
gather(.data, .recursive = TRUE)
ungroup(.data)
is.grouped(.data)
is.root()
}
\arguments{
  \item{.data}{A data sets represented by a pipe.}
  \item{.f}{Function with data frame argument and value}
  \item{\dots}{For group.f, additional arguments to f; for group, expressions that define grouping, such as column names (these are evaluated according to \link{non standard evaluation} rules)}
  \item{.recursive}{whether the data can be grouped in a tree like fashion, rather than a flat grouping}
  \item{.envir}{environment in which to evaluate \dots arguments}
}

\details{\code{group} is inspired by the SQL \code{GROUP BY} statement. In its simplest form, it allows to select some columns or variables to define the grouping, specified as \dots arguments. This means all rows sharing the same values for the grouping columns become part of the same group. The next step in complexity is grouping by R expressions, also specified as \dots arguments and evaluated according to \link{non standard evaluation} rules. An additional level in flexibility is offered by \code{group.f}, which allows to compute the grouping columns in a general R function that is only restricted to accept and return a data frame. \code{gather} is a shorthand for \code{group(data, constant)} which implies that all data should belong to single group. This is only feasible when the argument \code{.recursive} is set to \code{TRUE}, the default for \code{gather}, whereas the default for the same argument is \code{FALSE} for \code{group} and \code{group.f}. The recursive argument means that it is acceptable to subdivde each group and apply whatever operation the pipe describes to these subdivisions, then to the results thereof and so forth until only one subgroup remains, at which point the operation is applied one last time. The recursive and non-recursive modes are guaranteed to be equivalent only when the operation to be applied is associative and commutative and the model for this is the sum. No assumptions should be made as to the precise number and structure of the subdivisions. Multiple grouping operations applied to the same data set accumulate in the sense that each grouping is seen as a refinement of the existing one (this is a major departure from the equivalent SQL operation). Therefore \code{group(group(input(mtcars), cyl), mpg)} is equivalent to \code{group(input(mtcars), cyl, mpg)}. \code{ungroup} resets the grouping to the initial state, which is of arbitrary grouping (arbitrary grouping is best for performance). \code{is.grouped} tests if a data set is already grouped in any way other than arbitrary grouping. \code{is.root} is useful with recursive set to TRUE and can be used inside a function passed to \code{do} as an argument. It returns \code{TRUE} when the argument \code{x} represents a complete group as opposed to a subgroup.}

\value{A data set represented by a pipe for all but \code{is.grouped} and \code{is.root}, which return a \code{logical}}

\examples{
as.data.frame(
  select(
    group(
      input(mtcars), 
      cyl), 
    mean(mpg)))
    
as.data.frame(
  select(
    group.f(
      input(mtcars), 
      function(x) x$cyl), 
    mean(mpg)))
   
as.data.frame(
  do(
    gather(
      input(mtcars)),
    function(x) t(colSums(x))))
}
