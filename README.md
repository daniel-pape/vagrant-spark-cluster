# vagrant-spark-cluster

This repository accompanies the corresponding blog post at [codecentric's blog](https://blog.codecentric.de/en/2016/04/calculating-pi-apache-spark/).

The following parameters are customizable within the Vagrantfile:
* `$number_of_instances`, the number of worker nodes (it is assumed this is less than 10 for convenience; depending on your local hardware a larger number of instances will need more ressources than available on your system - take this in mind, when changing the parameter). The values defaults to 2.
