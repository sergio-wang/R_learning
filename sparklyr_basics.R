library(sparklyr)

# spark_install('3.0')

# spark_available_versions()
# spark_installed_versions()

# spark_uninstall(version = '2.4.5', hadoop = '2.7')

sc <- spark_connect(master= "local", version = '2.4')

cars <- copy_to(sc, mtcars)

library(DBI)
dbGetQuery(sc, 'SELECT count(*) FROM mtcars')

library(dplyr)
count(cars)

select(cars, hp, mpg) %>%
  sample_n(100) %>%
  collect() %>%
  plot()

model <- ml_linear_regression(cars, mpg ~ hp)
model

model %>%
  ml_predict(copy_to(sc, data.frame(hp = 250 + 10 * 1:10))) %>%
  transmute(hp = hp, mpg = prediction) %>%
  full_join(select(cars, hp, mpg)) %>%
  collect() %>%
  plot()

spark_write_csv(cars, "cars.csv")

cars <- spark_read_csv(sc, "cars.csv")

install.packages('sparklyr.nested')

sparklyr.nested::sdf_nest(cars, hp) %>%  # Important when dealing with JSON files
  group_by(cyl) %>%  
  summarise(data = collect_list(data))


# Last Resort, distributing my R code across the Spark cluster

#spark_apply() is to be used with caution, where spark falls short
cars %>% spark_apply(~round(.x))

# Streaming
dir.create("input")
write.csv(mtcars, "input/cars_1.csv", row.names = F)

stream <- stream_read_csv(sc, "input/") %>%
            select(mpg, cyl, disp) %>%
             stream_write_csv("output/")

dir("output", pattern = ".csv")

write.csv(mtcars, "input/cars_2.csv", row.names = F)

dir("output", pattern = ".csv")

stream_stop(stream)

spark_log(sc)

spark_disconnect(sc)

spark_disconnect_all()
