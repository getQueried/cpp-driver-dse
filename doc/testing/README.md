# Testing
Before proceeding ensure the tests were built using the [build procedures].

Both unit and integration tests use [Google Test](https://github.com/google/googletest/#google-test) and are packaged up into
the `dse-unit-tests` and `dse-integration-tests` binaries, respectively, in the build directory. Run the test program
with desired options:

```
# Run all integration tests
./dse-integration-tests

# List all unit test suites and the names of the tests they contain
./dse-unit-tests --gtest_list_tests

# Run a particular suite; the filter is simply a glob pattern.
./dse-unit-tests --gtest_filter=PointUnitTest*
```

Each test performs a [setup](#setup-dse), [execute](#execute-test), and
[teardown](#teardown-dse). This ensures that each test has a clean and
consistent run against the DSE instance during the execution
phase. Cluster instances are maintained for the entire duration of the test
unless the test is chaotic at which point the cluster will be destroyed at the
end.

Most of the tests performed will utilize a single node cluster; however a
cluster may be as large as nine nodes depending on the test being performed.

## Execution Sequences
### Setup DSE
```ditaa
/------------------\               /------------\                  /-------------\                  /----------\
| Integration Test |               | CCM Bridge |                  | CCM Machine |                  | CCM Tool |
| cYEL             |               | cBLK       |                  | cBLU        |                  |cBLK      |
\---------+--------/               \------+-----/                  \-------+-----/                  \-----+----/
          :                               :                                :                              :
          :  Create and Start Cluster     :                                :                              :
         +++---------------------------->+++ Establish SSH Connection      :                              :
         | |                             | |----------------------------->+++                             :
         | |                             | |       Connection Established | |                             :
         | |                             | |<-----------------------------| |                             :
         | |                             | | Create N-Node Cluster        | |                             :
         | |                             | |----------------------------->| | Execute Create Cluster      :
         | |                             | |                              | |--------------------------->+++
         | |                             | |                              | |         Download DSE       | |
         | |                             | |                              | |<---------------------------| |
         | |                             | |                              | |            Build DSE       | |
         | |                             | |                              | |<---------------------------| |
         | |                             | |                              | |              Start Cluster | |
         | |                             | |                              | |<---------------------------+++
         | |                             | |      DSE Cluster Ready       | |                             :
         | |     DSE Cluster is UP       | |<-----------------------------+++                             :
         +++<----------------------------+++                               :                              :
          :                               :                                :                              :
          :                               :                                :                              :

```

#### Execute Test
```ditaa
                /-----------\                                  /------------\
                | Unit Test |         Perform Test             | C++ Driver |
                | cYEL      +--------------------------------->| cBLU       |
                \-----+-----/                                  \------+-----/
                      ^                                               |
                      |                                               |
                      |             Validate Results                  |
                      +-----------------------------------------------+



   /------------\
   | C++ Driver |
/--+------------+--\                                                  /-------------\
| Integration Test |                   Perform Test                   | CCM Machine +------\
| cYEL             +------------------------------------------------->| cBLU        |NODE 1|
\--------+---------/                                                  |             +------/
         ^                                                            |             +------\
         |                                                            |             |NODE 2|
         |                           Validate Results                 |             +------/
         +-----------------------------------+------------------------+             +------\
                                             |                        |             |NODE 3|
                                             |                        |             +------/
                                             |                        \-------+-----/
                                             |                                |
                                             |                                |
                                             |                                |
                                   /---------+----------\                     |
                                   | DSE Cluster        |                     |
                                   | (or DSE)           |     Perform Test    |
                                   |                    +<--------------------+
                                   |                    |
                                   | {s}                |
                                   | cGRE               |
                                   \--------------------/
```

#### Teardown DSE
```ditaa
/------------------\               /------------\                  /-------------\                 /----------\
| Integration Test |               | CCM Bridge |                  | CCM Machine |                 | CCM Tool |
| cYEL             |               | cBLK       |                  | cBLU        |                 | cBLK     |
\---------+--------/               \------+-----/                  \-------+-----/                 \-----+----/
          :                               :                                :                             :
          :  Stop and Destroy Cluster     :                                :                             :
         +++---------------------------->+++ Establish SSH Connection      :                             :
         | |                             | |----------------------------->+++                            :
         | |                             | |       Connection Established | |                            :
         | |                             | |<-----------------------------| |                            :
         | |                             | | Destroy N-Node Cluster       | |                            :
         | |                             | |----------------------------->| | Remove Cluster             :
         | |                             | |                              | |-------------------------->+++
         | |                             | |                              | |  Stop DSE Instances       | |
         | |                             | |                              | |<--------------------------| |
         | |                             | |                              | |           Destroy Cluster | |
         | |                             | |                              | |<--------------------------+++
         | |                             | |            Cluster Destroyed | |                            :
         | |           Cluster Destroyed | |<-----------------------------+++                            :
         +++<----------------------------+++                               :                             :
          :                               :                                :                             :
          :                               :                                :                             :

```

[build procedures]: ../building/#test-dependencies-and-building-the-tests-not-required