data {
    /* N: Number of rows */
    int<lower=0> N;
    int<lower=0,upper=1> Y[N];
    int<lower=-1,upper=1> X_true[N];
    int<lower=0,upper=1> X_mis[N];
    int<lower=0> count[N];
    int<lower=0,upper=1> R_X[N];
}

transformed data {

}

parameters {
    /* Outcome model parameters */
    real beta0;
    real beta1;
    /* Error model parameter */
    real<lower=0,upper=1> phi[2,2];
    /* phi[1,1] = P(X_mis = 1 | X_true = 0, Y = 0) */
    /* phi[1,2] = P(X_mis = 1 | X_true = 0, Y = 1) */
    /* phi[2,1] = P(X_mis = 1 | X_true = 1, Y = 0) */
    /* phi[2,2] = P(X_mis = 1 | X_true = 1, Y = 1) */
    /* Covariate model parameter */
    /* psi = P(X_true = 1) */
    real<lower=0,upper=1> psi;
}

transformed parameters {

}

model {

    /* Priors */
    /*  Outcome model parameters */
    target += normal_lpdf(beta0 | 0, 100);
    target += normal_lpdf(beta1 | 0, 100);
    /*  Error model parameter */
    target += uniform_lpdf(phi[1,1] | 0, 1);
    target += uniform_lpdf(phi[1,2] | 0, 1);
    target += uniform_lpdf(phi[2,1] | 0, 1);
    target += uniform_lpdf(phi[2,2] | 0, 1);
    /*  Covariate model parameter */
    target += uniform_lpdf(psi | 0, 1);

    /* Loop over rows */
    for (i in 1:N) {
        if (R_X[i] == 1) {
            /* Contribution for a row with OBSERVED X */
            /* count[i] to account for the sample size */
            /*  Outcome model */
            target += count[i] * bernoulli_lpmf(Y[i] | inv_logit(beta0 + beta1 * X_true[i]));
            /*  Error model */
            target += count[i] * bernoulli_lpmf(X_mis[i] | phi[X_true[i]+1, Y[i]+1]);
            /*  Covariate model */
            target += count[i] * bernoulli_lpmf(X_true[i] | psi);

        } else {
            /* Contribution for a row with UNOBSERVED X (marginalized over X) */
            target += count[i] *
                log_sum_exp(/* X_true = 1 type contribution */
                            /* p(Yi|Xi=1,beta)p(Xi*|Xi=1,phi)p(Xi=1|psi) */
                            (log(psi)
                             /*  Outcome model */
                             + bernoulli_lpmf(Y[i] | inv_logit(beta0 + beta1))
                             /*  Error model */
                             + bernoulli_lpmf(X_mis[i] | phi[2, Y[i]+1])),
                            /* X_true = 0 type contribution */
                            /* p(Yi|Xi=0,beta)p(Xi*|Xi=0,phi)p(Xi=0|psi) */
                            (log(1-psi)
                             /*  Outcome model */
                             + bernoulli_lpmf(Y[i] | inv_logit(beta0))
                             /*  Error model */
                             + bernoulli_lpmf(X_mis[i] | phi[1, Y[i]+1])));
        }
    }

}

generated quantities {

}