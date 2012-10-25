context("Summary methods")

test_that("get_size_range_array",{
    data(species_params_gears)
    data(inter)
    params <- MizerParams(species_params_gears, inter)
    size_n <- get_size_range_array(params)
    expect_that(all(size_n), is_true())
    size_n <- get_size_range_array(params, min_w = 1)
    expect_that(!all(size_n[,which(params@w < 1)]), is_true())
    expect_that(all(size_n[,which(params@w >= 1)]), is_true())
    size_n <- get_size_range_array(params, max_w = 100)
    expect_that(all(size_n[,which(params@w <= 100)]), is_true())
    expect_that(!all(size_n[,which(params@w > 1)]), is_true())
    size_n <- get_size_range_array(params, min_w = 1, max_w = 100)
    expect_that(!all(size_n[,which(params@w > 100)]), is_true())
    expect_that(!all(size_n[,which(params@w < 1)]), is_true())
    expect_that(all(size_n[,which((params@w >= 1) & (params@w<=100))]), is_true())
    size_n <- get_size_range_array(params, min_l = 1)
    min_w <- params@species_params$a * 1 ^ params@species_params$b
    for (sp in 1:nrow(params@species_params)){ 
	expect_that(all(size_n[sp,which(params@w >= min_w[sp])]), is_true())
	expect_that(!all(size_n[sp,which(params@w < min_w[sp])]), is_true())
    }
    size_n <- get_size_range_array(params, max_l = 100)
    max_w <- params@species_params$a * 100 ^ params@species_params$b
    for (sp in 1:nrow(params@species_params)){ 
	expect_that(all(size_n[sp,which(params@w <= max_w[sp])]), is_true())
	expect_that(!all(size_n[sp,which(params@w > max_w[sp])]), is_true())
    }
    size_n <- get_size_range_array(params, min_l = 1, max_l = 100)
    min_w <- params@species_params$a * 1 ^ params@species_params$b
    max_w <- params@species_params$a * 100 ^ params@species_params$b
    for (sp in 1:nrow(params@species_params)){ 
	expect_that(all(size_n[sp,which((params@w <= max_w[sp]) & (params@w >= min_w[sp]))]), is_true())
	expect_that(!all(size_n[sp,which(params@w < min_w[sp])]), is_true())
	expect_that(!all(size_n[sp,which(params@w > max_w[sp])]), is_true())
    }
    size_n <- get_size_range_array(params, min_w = 1, max_l = 100)
    min_w <- rep(1,nrow(params@species_params))
    max_w <- params@species_params$a * 100 ^ params@species_params$b
    for (sp in 1:nrow(params@species_params)){ 
	expect_that(all(size_n[sp,which((params@w <= max_w[sp]) & (params@w >= min_w[sp]))]), is_true())
	expect_that(!all(size_n[sp,which(params@w < min_w[sp])]), is_true())
	expect_that(!all(size_n[sp,which(params@w > max_w[sp])]), is_true())
    }
    size_n <- get_size_range_array(params, min_l = 1, max_w = 100)
    min_w <- params@species_params$a * 1 ^ params@species_params$b
    max_w <- rep(100,nrow(params@species_params))
    for (sp in 1:nrow(params@species_params)){ 
	expect_that(all(size_n[sp,which((params@w <= max_w[sp]) & (params@w >= min_w[sp]))]), is_true())
	expect_that(!all(size_n[sp,which(params@w < min_w[sp])]), is_true())
	expect_that(!all(size_n[sp,which(params@w > max_w[sp])]), is_true())
    }
    expect_that(get_size_range_array(params, min_w = 1000, max_w = 1), throws_error())
    expect_that(get_size_range_array(params, min_l = 1000, max_l = 1), throws_error())
    expect_that(get_size_range_array(params, min_l = 1000, max_w = 1), throws_error())
    expect_that(get_size_range_array(params, min_w = 1000, max_l = 1), throws_error())
    # checking if fails if a and b not in species_params
    no_ab_params <- params
    no_ab_params@species_params <- params@species_params[,!(names(params@species_params) %in% c("a","b"))]
    expect_that(get_size_range_array(no_ab_params, min_l = 1, max_w = 100), throws_error())
})

test_that("get_time_elements",{
    data(species_params_gears)
    data(inter)
    params <- MizerParams(species_params_gears, inter)
    sim <- project(params, effort=1, t_max=10, dt = 0.5, t_save = 0.5)
    expect_that(length(get_time_elements(sim,as.character(3:4))), equals(dim(sim@n)[1]))
    expect_that(length(get_time_elements(sim,3:4)), equals(dim(sim@n)[1]))
    expect_that(sum(get_time_elements(sim,3:4)), equals(3))
    expect_that(sum(get_time_elements(sim,3:50)), throws_error())
    expect_that(which(get_time_elements(sim,seq(from=3,to=4,by = 0.1))), is_equivalent_to(c(7,8,9)))
    expect_that(length(get_time_elements(sim,seq(from=3,to=4,by = 0.1), slot_name="effort")), equals(dim(sim@effort)[1]))
})


test_that("getProportionOfLargeFish works",{
    data(species_params_gears)
    data(inter)
    params <- MizerParams(species_params_gears, inter)
    sim <- project(params, effort=1, t_max=20, dt = 0.5, t_save = 0.5)
    # noddy test - using full range of sizes
    prop <- getProportionOfLargeFish(sim, threshold_w = 500)
    t <- 41
    threshold_w <- sim@params@w > 500
    total_biomass <- sum(sweep(sim@n[t,,],2, sim@params@w * sim@params@dw, "*"))
    larger_biomass <- sum(sweep(sim@n[t,,],2, threshold_w * sim@params@w * sim@params@dw, "*"))
    expect_that(prop[t] , is_equivalent_to(larger_biomass / total_biomass))
    # using a size range
    prop <- getProportionOfLargeFish(sim, min_w = 10, max_w = 5000, threshold_w = 500)
    range_w <- (sim@params@w >= 10) & (sim@params@w <= 5000)
    threshold_w <- sim@params@w > 500
    total_biomass <- sum(sweep(sim@n[t,,],2, range_w * sim@params@w * sim@params@dw, "*"))
    larger_biomass <- sum(sweep(sim@n[t,,],2, threshold_w * range_w * sim@params@w * sim@params@dw, "*"))
    expect_that(prop[t] , is_equivalent_to(larger_biomass / total_biomass))
})


test_that("check_species works",{
    data(species_params_gears)
    data(inter)
    params <- MizerParams(species_params_gears, inter)
    sim <- project(params, effort=1, t_max=20, dt = 0.5, t_save = 0.5)
    expect_that(check_species(sim,c("Cod","Haddock")), is_true())
    expect_that(check_species(sim,c(10,11)), is_true())
    expect_that(check_species(sim,c("Arse","Balls")), throws_error())
    expect_that(check_species(sim,c(10,666)), throws_error())

})

test_that("getMeanWeight works",{
    data(species_params_gears)
    data(inter)
    params <- MizerParams(species_params_gears, inter)
    sim <- project(params, effort=1, t_max=20, dt = 0.5, t_save = 0.5)
    # all species, all size range
    total_biomass <- apply(sweep(sim@n, 3, sim@params@w * sim@params@dw, "*"),1,sum)
    total_n  <- apply(sweep(sim@n, 3, sim@params@dw, "*"),1,sum)
    mw1 <- total_biomass / total_n
    mw <- getMeanWeight(sim)
    expect_that(mw, equals(mw1))
    # select species
    species <- c("Cod","Haddock")
    total_biomass <- apply(sweep(sim@n[,species,], 3, sim@params@w * sim@params@dw, "*"),1,sum)
    total_n  <- apply(sweep(sim@n[,species,], 3, sim@params@dw, "*"),1,sum)
    mw2 <- total_biomass / total_n
    mw <- getMeanWeight(sim, species = species)
    expect_that(mw, equals(mw2))
    # select size range
    min_w <- 10
    max_w <- 10000
    size_n <- get_size_range_array(sim@params, min_w = min_w, max_w = max_w)
    total_biomass <- apply(sweep(sweep(sim@n, c(2,3), size_n, "*"), 3, sim@params@w * sim@params@dw, "*"),1,sum)
    total_n <- apply(sweep(sweep(sim@n, c(2,3), size_n, "*"), 3, sim@params@dw, "*"),1,sum)
    mw3 <- total_biomass / total_n
    mw <- getMeanWeight(sim, min_w = min_w, max_w=max_w)
    expect_that(mw, equals(mw3))
    # select size range and species
    total_biomass <- apply(sweep(sweep(sim@n, c(2,3), size_n, "*")[,species,], 3, sim@params@w * sim@params@dw, "*"),1,sum)
    total_n <- apply(sweep(sweep(sim@n, c(2,3), size_n, "*")[,species,], 3, sim@params@dw, "*"),1,sum)
    mw4 <- total_biomass / total_n
    mw <- getMeanWeight(sim, species=species, min_w = min_w, max_w=max_w)
    expect_that(mw, equals(mw4))
    # errors
    expect_that(getMeanWeight(sim,species=c("Dougal","Ted")), throws_error())
})



