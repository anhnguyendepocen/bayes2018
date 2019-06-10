data {
    // Hypeparameters for lambda[1]
    real<lower=0> lambda1_mean;
    real<lower=0> lambda1_length_w;
    // Hyperparameter for lambda[k]
    real<lower=0> w;
    real<lower=0> lambda_star;
    // Hyperparameter for beta
    real beta_mean;
    real<lower=0> beta_sd;
    // Number of pieces
    int<lower=0> K;
    // Cutopoints on time
    //  cutpoints[1] = 0
    //  max(event time) < cutpoints[K+1] < Inf
    //  K+1 elements
    real cutpoints[K+1];
    //
    int<lower=0> N;
    int<lower=0,upper=1> cens[N];
    real y[N];
    int<lower=0,upper=1> x[N];
    //
    // grids for evaluating posterior predictions
    int<lower=0> grid_size;
    real grid[grid_size];
}

transformed data {
}

parameters {
    // Baseline hazards
    real<lower=0> lambda[K];
    // Effect of group
    real beta;
}

transformed parameters {
}

model {
    // Prior on beta
    target += normal_lpdf(beta | beta_mean, beta_sd);

    // Loop over pieces of time
    for (k in 1:K) {
        // k = 1,2,...,K
        // cutpoints[1] = 0
        // cutpoints[K+1] > max event time
        real length = cutpoints[k+1] - cutpoints[k];

        // Prior on lambda
        // BIDA 13.2.5 Priors for lambda
        if (k == 1) {
            // The first interval requires special handling.
            target += gamma_lpdf(lambda[1] | lambda1_mean * lambda1_length_w, lambda1_length_w);
        } else {
            // Mean lambda_star
            target += gamma_lpdf(lambda[k] | lambda_star * length * w, length * w);
        }

        // Likelihood contribution
        // BIDA 13.2.3 Likelihood for piecewise hazard PH model
        for (i in 1:N) {
            // Linear predictor
            real lp = beta * x[i];
            // Everyone will contribute to the survival part.
            if (y[i] >= cutpoints[k+1]) {
                // If surviving beyond the end of the interval,
                // contribute survival throughout the interval.
                target += -exp(lp) * (lambda[k] * length);
                //
            } else if (cutpoints[k] <= y[i] && y[i] < cutpoints[k+1]) {
                // If ending follow up during the interval,
                // contribute survival until the end of follow up.
                target += -exp(lp) * (lambda[k] * (y[i] - cutpoints[k]));
                //
                // Event individuals also contribute to the hazard part.
                if (cens[i] == 1) {
                    target += lp + log(lambda[k]);
                }
            } else {
                // If having ended follow up before this interval,
                // no contribution in this interval.
            }
        }
    }
}

generated quantities {
    // Hazard function evaluated at grids
    real<lower=0> h_grid[grid_size];
    // Cumulative hazard function at grids
    real<lower=0> H_grid[grid_size];

    // Loop over cutpoints
    for (k in 1:K) {
        // At each k, hazard is constant at lambda[k]
        // Loop over grid points
        for (g in 1:grid_size) {
            if(cutpoints[k] <= grid[g] && grid[g] < cutpoints[k+1]) {
                h_grid[k] = lambda[k];
            }
        }
    }
}
