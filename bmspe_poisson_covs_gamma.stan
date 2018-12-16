data {
    /* Hyperparameters*/
    real<lower=0> a;
    real<lower=0> b;
    real<lower=0> s;

    /* Dimensions */
    int<lower=0> N;
    int<lower=0> M;
    /* Design Matrix */
    matrix[N,M] X;
    /* Outcome */
    int<lower=0> y[N];
}

parameters {
    vector[M] beta;
    vector<lower=0>[N] gamma;
    real<lower=0> aa;
    real<lower=0> bb;
}

transformed parameters {
    vector[N] eta;
    vector<lower=0>[N] mu;

    eta = X * beta;
    mu = exp(eta);
}

model {
    /* Prior */
    for (j in 1:M) {
        /* beta_j ~ N(0, s) */
        target += normal_lpdf(beta[j] | 0, s);
    }
    /* aa ~ Gamma(a, b) */
    target += gamma_lpdf(aa | a, b);
    /* bb ~ Gamma(a, b) */
    target += gamma_lpdf(bb | a, b);

    /* Likelihood */
    for (i in 1:N) {
        /* gamma_i ~ Gamma(aa, bb) */
        target += gamma_lpdf(gamma[i] | aa, bb);
        /* y_i ~ poisson(gamma_i * mu_i); */
        target += poisson_lpmf(y[i] | gamma[i] * mu[i]);
    }
}

generated quantities {
    int y_new[N];
    for (i in 1:N) {
        if (1 < 0) {
            /* To avoid erros like the below during the warmup. */
            /* Check posterior predictive. */
            y_new[i] = -1;
        } else {
            y_new[i] = poisson_rng(gamma[i] * mu[i]);
        }
    }
}
