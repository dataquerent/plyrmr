# Copyright 2013 Revolution Analytics
#    
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

merge.pipe = 
	function(
		x, 
		y, 
		by = NULL, 
		by.x = by, 
		by.y = by, 
		all = FALSE, 
		all.x = all, 
		all.y = all, 
		suffixes = c(".x", ".y"), 
		incomparables = NULL,
		...) {
		stopifnot((all.x && all.y) == all)
		ox = output(x)
		oy = output(y)
		stopifnot(ox$format == oy$format)
		map.x =	
			function(k,v) 
				keyval(
					if(is.null(by.x)) v else	v[, by.x], 
					v)
		map.y =	
			function(k,v) 
				keyval(
					if(is.null(by.y)) v else	v[, by.y], 
					v)
		input(
			equijoin(
				ox$data, 
				oy$data,
				input.format = ox$format,
				outer = 
					list(NULL, "full", "left", "right")[c((!all.x && !all.y), all, all.x, all.y)][[1]],
				map.left = map.x,
				map.right = map.y,
				reduce = 
					function(k, x, y) {
						by = {
							if(is.null(by)) 
								intersect(names(x), names(y))
							else by}
						by.x = {
							if(is.null(by.x)) by
							else by.x} 
						by.y = {
							if(is.null(by.y)) by
							else by.y}
						merge(
							x, 
							y, 
							by = by, 
							by.x = by.x,
							by.y = by.y,
							all = all, 
							all.x = all.x, 
							all.y = all.y,
							suffixes = suffixes,
							incomparables = incomparables)
					}))}

quantile.cols = function(x, ...) UseMethod("quantile.cols")

quantile.cols.pipe = 
	function(x, ...) {
		N = rmr.options("keyval.length")/10
		midprobs  = 
			function() {
				probs = seq(0, 1, 1/N)
				(probs[-1] + probs[-length(probs)])/2}
		map = 
			function(.x) {
				args = c(list(.x), list(...))
				args$weights = rep(1, nrow(.x))
				args$verbose = TRUE
				args$probs = midprobs()
				sink(stderr())
				y =
					cbind(
						t(do.call(wquantile, args)), 
						.weight = nrow(.x)/N)
				sink()
				y}
		combine = 
			function(.x) {
				args = c(list(.x[,-ncol(.x)]), list(...))
				args$weights = .x$.weight
				args$verbose = TRUE
				#				args$names = FALSE
				args$probs = midprobs() 
				sink(stderr())
				y =
					cbind(
						t(do.call(wquantile, args)), 
						.weight = sum(args$weights)/N)
				sink()
				y}
		reduce = 
			function(.x) {
				if(is.root()){
					quantile.cols(
						as.data.frame(
							combine(.x))[,-ncol(.x)], 
						...)}
				else
					combine(.x)}
		do(gather(do(x, map)), reduce)}


quantile.cols.data.frame = 
	function(x, ...) 
		splat(data.frame)(
			strip.nulls(
				lapply(
					x,
					function(.y)
						if(is.numeric(.y))
							quantile(.y, ...))))

# quantile.data.frame =
# 	function(x, probs = seq(0, 1, 0.25), ...) {
# 		if(!is.null(x$.weights))
# 			x$.weights = 1
# 	  x = x[splat(order)(select(x, ...)), ]
# 	  x[pmax(1, round(nrow(x) * probs)), ]}

count.cols = function(x, ...) UseMethod("count.cols")

count.cols.default = 
	function(x)
		arrange(
			as.data.frame(table(x)), 
			Freq)

count.cols.data.frame =
	function(x) 
		splat(data.frame.fill)( 
			strip.nulls(
				lapply(
					x,
					function(z)
						if(!is.numeric(z))
							count.cols(z))))

merge.counts = 
	function(x, n) {
		merge.one =
			function(x)
				ddply(x, 1, function(x) {y = sum(x[, 2]); names(y) = names(x)[2]; y})		
		prune = 
			function(x, n) {
				if(is.null(n) || nrow(x) <= n) x
				else {
					x = x[order(x[,2], decreasing = TRUE),]
					x[,2] = x[,2] - x[n+1, 2]
					x[x[,2] > 0, ]}}
		splat(data.frame.fill) (
				lapply(
					1:((ncol(x) - 1)/2),
					function(i) prune(merge.one(x[,c(2*i, 2*i + 1)]), n)))}

count.cols.pipe = 
	function(x, n = Inf)
		do(
			gather(
				do(
					x,
					count.cols)),
			Curry(merge.counts, n = n))

extreme.k= 
	function(.x, .k , ...,  .decreasing, .envir = parent.frame()) {
		force(.envir)
		this.order = Curry(order, decreasing = .decreasing)
		mr.fun = 
			function(.x) 
				head(
					.x[
						do.call(
							this.order,
							select(.x, ..., .envir = .envir)),
						,
						drop = FALSE], 
					.k)
		ungroup(
			do(
				gather(
					do(.x, mr.fun)),
				mr.fun))}

top.k = 
	function(.x, .k = 1, ...,  .envir = parent.frame()) {
		force(.envir)
		extreme.k(.x, .k = .k, ..., .decreasing = TRUE, .envir = .envir)}

bottom.k = 
	function(.x, .k = 1, ..., .envir = parent.frame()) {
		force(.envir)
		extreme.k(.x, .k = .k, ..., .decreasing = FALSE, .envir = .envir)}

moving.window = 
	function(x, index, window, R = rmr.options("keyval.length")) {
		partition = 
			function(x) {
				part = 
					function(index, shift)
						ceiling((index + shift*(window - 1))/R)
				index = unlist(x[, index])
				stopifnot(length(index) == nrow(x))
				partT = part(index, T)
				partF = part(index, F)
				unique(
					cbind(
						.part = c(partT, partF), 
						rbind(x, x)))}
		group(
			do(
				x, 
				partition), 
			.part)}

unique.pipe = 
	function(x, incomparables = FALSE, fromLast = FALSE, ...) {
		uniquec = Curry(unique, incomparables = incomparables, fromLast = fromLast)
		do(
			group.f(
				do(x, uniquec),
				identity,
				.recursive = TRUE),
			uniquec)}

rbind = function(...) UseMethod("rbind")
rbind.default = base::rbind
rbind.pipe = function(...)
	do(input(lapply(list(...), output)), identity)

union = function(x,y) UseMethod("union")
union.default = base::union
union.pipe = 
	union.data.frame = 
	function(x, y) unique(rbind(x,y))

intersect = function(x,y) UseMethod("intersect")
intersect.default = base::intersect
intersect.data.frame = 
	intersect.pipe = 
	function(x,y)
		unique(merge(x,y))
# 	
# arrange(
# 	as.data.frame(
# 		do(
# 			group.f(
# 				input(uns), 
# 				function(x) sapply(qu$x, function(t) c(r = sum(x$x > t)))), 
# 			#function(x) cbind(x, rank(x$x)))), 
# 			identity)),
# 	x)