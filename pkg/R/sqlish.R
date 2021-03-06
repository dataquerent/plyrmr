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

setMethodS3(
	"where",
	"pipe",
	function(.data, ..., .envir = parent.frame()) {
		force(.envir)
		do(.data, CurryHalfLazy(where, .envir = .envir), ...)})

setMethodS3(
	"select",
	"pipe",
	function(.data, ..., .replace = TRUE, .envir = parent.frame()) {
		force(.envir)
		do(.data, CurryHalfLazy(select, .replace = .replace, .envir = .envir), ...)})