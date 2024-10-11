#jinja2: trim_blocks:False
{%if groups['compute_node'] | map('extract', hostvars, 'gpu_count') | select('defined') | default([0], true) | map('int') | sum > 0 %}{# checks if this group is having GPUs and then creates content #}
# How to use GPU nodes

## About GPU nodes

{{ slurm_cluster_name | capitalize }} has in total {{ groups['compute_node'] | default([0], true) | map('int') | count }} compute nodes. {{ groups['compute_node'] | default([0], true) | map('int') | count - groups['compute_node'] | map('extract', hostvars, 'gpu_count') | select('defined') | default([0], true) | map('int') | count }} regular nodes and {{ groups['compute_node'] | map('extract', hostvars, 'gpu_count') | select('defined') | default([0], true) | map('int') | count }}  GPU nodes with {{ groups['compute_node'] | map('extract', hostvars, 'gpu_count') | select('defined') | default([0], true) | map('int') | max }} x GPU ({{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | unique | join(', ') }}) devices. The GPU nodes are placed in slurm partitions called `{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | unique | join('` `') }}`.

GPU jobs can be submitted to Slurm with either [sbatch](../analysis/#1-batch-jobs) or [srun](../analysis/#2-interactive-jobs) commands, containing either:

 - `gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:#` argument - where `#` is the number of specific node of nodes to be reserved. For example, a job that uses 1 node with 2 GPU's, would use `gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2`, where `{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}` is the type of GPU card requested. Alternatively you can also provide
 -  `--gpus-per-node={{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:#`, where `#` is again the number of GPUs requested per node.

Note that users can request only a number of **entire** GPUs and hence **NOT partial** GPU resources. For example, you can request 1, 2 or more GPU(s), but you cannot request 1 GPU with a specific amount of `GPU cores` or `GPU memory`.
The selection of individual resources is possible on newer GPUs that support [MIG](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html) feature. This feature is available only on newer types, like A30 and A100, but not on our A40.

## Examples 1 and 2: Submitting a batch and an interactive job

Example 1 shows how to submit the `gpu_test.sbatch` file, requesting 2 GPU devices and executing a command that prints the information of the allocated GPU devices:

```bash
    $ cat gpu_test.sbatch
    #!/bin/bash
    #SBATCH --gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2
    #SBATCH --job-name=gpu_test
    #SBATCH --output=gpu_test.out
    #SBATCH --error=gpu_test.err
    #SBATCH --time=01:00:00
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=1gb
    #SBATCH --nodes=1
    #SBATCH --export=NONE
 
    nvidia-smi
    $ sbatch gpu_test.sbatch
```

Or can be use as the argument on the command line

```bash
    $ sbatch --gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2 my.sbatch
```

Example 2 runs the same GPU example in an interactive session using `srun`.

```bash
    $ mkdir -p /groups/umcg-GROUP/tmpXX/projects/${USER}/gpu_test
    $ cd /groups/umcg-GROUP/tmpXX/projects/${USER}/gpu_test
    $ srun --qos=interactive-short --gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2 --time=01:00:00 --pty bash -i
    $ echo ${SLURM_GPUS_ON_NODE}
    2  
```

Replace `GROUP` and `tmpXX` placeholders with correct values for group and tmp filesystem. The returned value is the number of GPU's available for the job. Use the `nvidia-smi` command to see more information about the GPU devices that are available inside the job.

```bash
    $ nvidia-smi 
    Mon Jul 24 12:45:15 2023       
    +---------------------------------------------------------------------------------------+
    | NVIDIA-SMI 535.54.03              Driver Version: 535.54.03    CUDA Version: 12.2     |
    |-----------------------------------------+----------------------+----------------------+
    | GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
    | Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
    |                                         |                      |               MIG M. |
    |=========================================+======================+======================|
    |   0  NVIDIA A40                     On  | 00000000:00:08.0 Off |                    0 |
    |  0%   30C    P8              21W / 300W |      4MiB / 46068MiB |      0%      Default |
    |                                         |                      |                  N/A |
    +-----------------------------------------+----------------------+----------------------+
    |   1  NVIDIA A40                     On  | 00000000:00:09.0 Off |                    0 |
    |  0%   29C    P8              21W / 300W |      4MiB / 46068MiB |      0%      Default |
    |                                         |                      |                  N/A |
    +-----------------------------------------+----------------------+----------------------+
                                                                                             
    +---------------------------------------------------------------------------------------+
    | Processes:                                                                            |
    |  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
    |        ID   ID                                                             Usage      |
    |=======================================================================================|
    |  No running processes found                                                           |
    +---------------------------------------------------------------------------------------+
```

Note that like any other interactive jobs, this one is also limited to one interactive job per user.

As you can tell from the example above, once the job has started, the environment variable called `SLURM_GPUS_ON_NODE` is created. It contains the number of available GPU's of the currently running job. The value from the example above would be set to `2`. Furthermore, you can access only the two that are assigned to the job. This means you won't be able to use any other GPU's on the node. This is limited by SLURM's control groups and prevents users consuming resources that they have not requested.

To show the current jobs and how much GPU's they are using

```bash
    $ squeue -o "%.10i %.20j %.10u %.2t %.10M %.5D %.15R %.15b %.15P"  
        JOBID       NAME       USER  ST      TIME NODES  NODELIST(REASON)  TRES_PER_NODE   PARTITION  
         1234       bash umcg-user1  R       8:27     1   nb-vcompute05   gres:gpu:a40:2     gpu_a40 
         1235    somejob umcg-user2  R    2:09:14     1   nb-vcompute05              N/A     gpu_a40  
         1236    somejob umcg-user3  R    2:19:53     1   nb-vcompute04              N/A     gpu_a40  
          ...
```

and the GPU's used are available on the column before the last.

## Example 2: Build and run CUDA source sample

This example shows how to build and run [CUDA code sample](https://developer.nvidia.com/cuda-code-samples) (version 12.2.0 compiled with CUDA/12.2.0) in the interactive job.

First you must be sure that you have a driver version same or higher as the samples version, that is:

```
    [ driver version ] and [ CUDA version ] >= [ samples version ]
```

To check the driver and cuda version, run `nvidia-smi` on the compute node and check version numbers - they should be printed on the top-middle and top-right corner of the output.

```bash
    [nibbler ~]$ # replace the YYY with apropriate values
    [nibbler ~]$ mkdir -p /groups/umcg-YYY/tmpYY/users/umcg-YYY/cuda_samples
    [nibbler ~]$ cd /groups/umcg-YYY/tmpYY/users/umcg-YYY/cuda_samples
    [nibbler cuda_samples]$ wget https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v12.2.tar.gz -O - | tar -xz
    [nibbler UnifiedMemoryPerf]$ cd cuda-samples-12.2/Samples/6_Performance/UnifiedMemoryPerf
    [nibbler UnifiedMemoryPerf]$ # increase the matrix size, so that the calulation takes long enough to capture on nvidia-smi
    [nibbler UnifiedMemoryPerf]$ sed -i 's/maxSampleSizeInMb = 64/maxSampleSizeInMb = 1024/' matrixMultiplyPerf.cu
    [nibbler UnifiedMemoryPerf]$ srun --qos=interactive-short --gpus-per-node={{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2 --mem=20G --time=01:00:00 --pty bash -i
    [nb-node-b02 UnifiedMemoryPerf]$ ml CUDA/12.2.0          # load CUDA compiler and libraries
    [nb-node-b02 UnifiedMemoryPerf]$ make                    # compile the current example
    [nb-node-b02 UnifiedMemoryPerf]$ # run test on second device (note first device is '0',second is '1' etc.)
    [nb-node-b02 UnifiedMemoryPerf]$ ./UnifiedMemoryPerf -device=1 > gpu_test.log &
    [nb-node-b02 UnifiedMemoryPerf]$ nvidia-smi 
    Mon Jul 24 12:53:08 2023       
    +---------------------------------------------------------------------------------------+
    | NVIDIA-SMI 535.54.03              Driver Version: 535.54.03    CUDA Version: 12.2     |
    |-----------------------------------------+----------------------+----------------------+
    | GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
    | Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
    |                                         |                      |               MIG M. |
    |=========================================+======================+======================|
    |   0  NVIDIA A40                     On  | 00000000:00:08.0 Off |                    0 |
    |  0%   34C    P0              77W / 300W |      7MiB / 46068MiB |      0%      Default |
    |                                         |                      |                  N/A |
    +-----------------------------------------+----------------------+----------------------+
    |   1  NVIDIA A40                     On  | 00000000:00:09.0 Off |                    0 |
    |  0%   41C    P0              96W / 300W |    376MiB / 46068MiB |    100%      Default |
    |                                         |                      |                  N/A |
    +-----------------------------------------+----------------------+----------------------+
                                                                                             
    +---------------------------------------------------------------------------------------+
    | Processes:                                                                            |
    |  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
    |        ID   ID                                                             Usage      |
    |=======================================================================================|
    |    1   N/A  N/A     15455      C   ./UnifiedMemoryPerf                         260MiB |
    +---------------------------------------------------------------------------------------+
```

## Example 3: Tensorflow inside Apptainer

This example shows how to run a Tensorflow python job inside Apptainer, using 1 node with 2 GPU devices and CUDA module.

This example shows how to download the latest GPU tensorflow container image and execute some test job inside it.

To run this example

1. create the working directory on the `tmp` filesystem and navigate into it
   ```bash
   [nibbler ~]$ # create a working directory and set it as a working directory
   [nibbler ~]$ mkdir /groups/umcg-YYY/tmpYY/users/umcg-YYY/gpu_apptainer_test
   [nibbler ~]$ cd /groups/umcg-YYY/tmpYY/users/umcg-YYY/gpu_apptainer_test
   ```
2. Create two file
    1. a `apptainer_tensorflow.slurm` - a job description file for the SLURM queuing system
    2. a `training.py` - a simplest Tensorflow traning example script, containing only 30 lines

Where `apptainer_tensorflow.slurm` file contains

```bash
#!/bin/bash
#SBATCH --gres=gpu:{{ groups['compute_node'] | map('extract', hostvars, 'gpu_type') | select('defined') | first }}:2
#SBATCH --job-name=apptainer_tf
#SBATCH --output=apptainer_tf.out
#SBATCH --error=apptainer_tf.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --nodes=1
#SBATCH --export=NONE

## Environment
# Load latest CUDA environment module
ml CUDA

### Running
# run tensorflow .sif image that is saved in the /apps/data/containers/ and execute the training.py script
[nibbler gpu_apptainer_test]$ apptainer run -B $(pwd) --nv /apps/data/containers/tensorflow-2.13.0-gpu.sif python training.py
```

and the `training.py` file contains

```python
## From https://www.tensorflow.org/tutorials/quickstart/beginner
import tensorflow as tf
print("TensorFlow version:", tf.__version__)
mnist = tf.keras.datasets.mnist
(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0
model = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dropout(0.2),
  tf.keras.layers.Dense(10)
])
predictions = model(x_train[:1]).numpy()
predictions
tf.nn.softmax(predictions).numpy()
loss_fn = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)
loss_fn(y_train[:1], predictions).numpy()
model.compile(optimizer='adam',
              loss=loss_fn,
              metrics=['accuracy'])
model.fit(x_train, y_train, epochs=5)
model.evaluate(x_test,  y_test, verbose=2)
probability_model = tf.keras.Sequential([
  model,
  tf.keras.layers.Softmax()
])
probability_model(x_test[:5])
```

This basic training python script example

1. loads [MNIST](http://yann.lecun.com/exdb/mnist/) database of handwritten digits,
2. builds a neural network machine learning model that classifies images,
3. trains this neural network and
4. evaluates the accuracy of the model.

## Additional documentation

1. [TensorFlow 2 quickstart for beginners](https://www.tensorflow.org/tutorials/quickstart/beginner)
2. [NVidia Tesla documentation](https://docs.nvidia.com/datacenter/tesla/)
3. [CUDA Code Samples](https://developer.nvidia.com/cuda-code-samples)
4. [Apptainer GPU Support documentation](https://apptainer.org/docs/user/1.1/gpu.html)

{% else %}{# else this stack does not have any GPUs and should create a simple content stating this #}
## This computer does not have any GPU co-processing hardware

{% endif %}
