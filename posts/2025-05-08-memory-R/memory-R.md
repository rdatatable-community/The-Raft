Profiling memory in R was always not a trival task.  
In this post I would like to emphasize that currently popular methods are very much inaccurate, therefore should be used with caution, and more importantly, should not be used to draw conclusions about actual memory usage of an R functions.  

The root cause of inaccuracy of many memory profiling tools in R is that they measure memory allocated by R (including R's C) code. They do not take into account memory allocated using C.  

Following example should make it very clear.  

Below R chunk is the content of `memtest.R` file.
```r
code = "
  int nx = LENGTH(x);
  double *y = (double*)(
    LOGICAL(r_alloc)[0] ?
      R_alloc(nx, sizeof(double)) : // allocated by R's C
      malloc(nx * sizeof(double))   // allocated by C
  );
  double *xp = REAL(x);
  // populate y
  for (int i=0; i<nx; i++)
    y[i] = xp[i];
  // do something with y
  for (int i=1; i<nx; i++)
    y[i] = y[i-1]+y[i];
  // sum double array to ensure compiler wont optimize it away
  double sum = 0.0;
  for (int i=0; i<nx; i++)
    sum += y[i];
  SEXP res = PROTECT(Rf_allocVector(REALSXP, 1));
  REAL(res)[0] = sum;
  if (!LOGICAL(r_alloc)[0])
    free(y);
  UNPROTECT(1);
  return res;
"
funx = inline::cfunction(signature(x="numeric", r_alloc="logical"), code, language="C")
set.seed(108)
x = rnorm(1e8)
```

First we will ensure that results are the same, no matter if we allocate temporary working memory using R or C:

```sh
Rscript -e 'source("memtest.R"); funx(x, r_alloc=TRUE)'
#[1] 1.160649e+12
Rscript -e 'source("memtest.R"); funx(x, r_alloc=FALSE)'
#[1] 1.160649e+12
```

Next we will use the most popular, at present, package for profiling memory `bench`:

```sh
Rscript -e 'source("memtest.R"); bench::mark(funx(x, r_alloc=TRUE))'
## A tibble: 1 × 13
#  expression      min median `itr/sec` mem_alloc `gc/sec` n_itr  n_gc total_time
#  <bch:expr>    <bch> <bch:>     <dbl> <bch:byt>    <dbl> <int> <dbl>   <bch:tm>
#1 funx(x, r_al… 577ms  577ms      1.73     763MB     1.73     1     1      577ms
Rscript -e 'source("memtest.R"); bench::mark(funx(x, r_alloc=FALSE))'
## A tibble: 1 × 13
#  expression      min median `itr/sec` mem_alloc `gc/sec` n_itr  n_gc total_time
#  <bch:expr>    <bch> <bch:>     <dbl> <bch:byt>    <dbl> <int> <dbl>   <bch:tm>
#1 funx(x, r_al… 589ms  589ms      1.70        0B        0     1     0      589ms
```

As we can see in output of `mark` function, `mem_alloc` is reported to be 0B when we use `malloc`, while for `R_alloc` it reports 763MB. The difference we observe here should serve as a warning. If one wants to use `mark` function to draw conculsion about memory usage, one should as well examine source code of the function that is being benchmarked.

It is worth to note that `?mark` explains this issue:

> `mem_alloc` - `bench_bytes` Total amount of memory allocated by R while running the expression. Memory allocated outside the R heap, e.g. by `malloc()` or `new` directly is not tracked, take care to avoid misinterpreting the results if running code that may do this.

Unfortunately people are not aware of it and often publish memory usage benchmarks believing they are accurate.

Lastly we will use external process to measure memory, [cgmemtime](https://github.com/gsauthof), proposed by Matt Dowle in 2014 during his work on [2B rows data.frame grouping benchmark](https://github.com/Rdatatable/data.table/wiki/Benchmarks-:-Grouping).

> `cgmemtime` measures the high-water RSS+CACHE memory usage of a process and its descendant processes.

```sh
./cgmemtime Rscript -e 'source("memtest.R"); funx(x, r_alloc=TRUE)'
#child_RSS_high:    1641808 KiB
#group_mem_high:    1626264 KiB
./cgmemtime Rscript -e 'source("memtest.R"); funx(x, r_alloc=FALSE)'
#child_RSS_high:    1641096 KiB
#group_mem_high:    1625820 KiB
```

While `cgmemtime` will report very accurate memory usage statistics, it won't be able to measure memory of a single function call as it tracks memory for a whole process.

```sh
./cgmemtime Rscript -e 'source("memtest.R");'
#child_RSS_high:     860884 KiB
#group_mem_high:     843844 KiB
```

In order to get a memory usage of an R function call, in this simple example, we can measure all the rest, without the actual `funx()` call, and then subtract one from another.
```r
(1641096-860884)/1024
#[1] 761.9258
```

I hope this post will help people to be a bit more sceptical when reading R's memory benchmarks.
