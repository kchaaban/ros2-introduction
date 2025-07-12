<header>

<!--
  <<< Author notes: Course header >>>
  Include a 1280×640 image, course title in sentence case, and a concise description in emphasis.
  In your repository settings: enable template repository, add your 1280×640 social image, auto delete head branches.
  Add your open source license, GitHub uses MIT license.
-->

# Introduction to ROS2

_Get started developping robotics applications using ros2._

</header>

<!--
  <<< Author notes: Step 1 >>>
  Choose 3-5 steps for your course.
  The first step is always the hardest, so pick something easy!
  Link to docs.github.com for further explanations.
  Encourage users to open new tabs for steps!
-->

## Step 1: Install ROS2 Humble


**1.1: Download and Install ROS 2 Humble** <br>
**1.2: Configuration and setup of the developpement environnement**<br>
**1.3: Extra useful app and tools**<br>

**1.1: Download and Install ROS 2 Humble**: 
Download and install Ubuntu 22.04 image:<br>
https://cdimage.ubuntu.com/jammy/daily-live/current/

Choose desktop image file based on your machine architecture: amd vs arm <br>

<p> <em> Set locale: </em> <p> 
locale  # check for UTF-8 <br>
sudo apt update && sudo apt install locales <br>
sudo locale-gen en_US en_US.UTF-8<br>
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 <br>
export LANG=en_US.UTF-8 <br>
locale  # verify settings! <br>

<p> <em>Setup sources: </em></p>
sudo apt install software-properties-common <br>
sudo add-apt-repository universe <br>
sudo apt update && sudo apt install curl -y <br>
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
<br>
<br>
<p> <em>Install ROS 2 packages</em> </p>
sudo apt update <br>
sudo apt upgrade <br>
sudo apt install ros-humble-desktop <br>
sudo apt install ros-dev-tools	<br>
<br>

**1.2: Configuration and setup of the developpement environnement**

echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc <br>
source ~/.bashrc # to execute one time <br>

**1.3: Extra useful app and tools**

<p> <b>Visual code: </b> </p>
Download .deb package of visual code at (Be careful to choose the correct file depending on your architecture arm, amd, …): <br>
https://code.visualstudio.com/Download  <br>
Install visual code code:  <br>
sudo dpkg -i ~/path/to/code_1.XXX.deb  <br>
 <br>
In case dpkg complains about missing dependencies, run: <br>
sudo apt -f install <br>
 
To lunch visual code, run the command:  <br>
code .   <br>
 <br>
It is recommended to add visual code to your favourites as seen in the figure here  <br>
![image](https://github.com/user-attachments/assets/b114fba3-3577-44ab-9bfe-5083d30fe607)

<p> <b>Terminator: </b> </p>
sudo apt-get update <br>
sudo apt-get install terminator <br>

You can split it horizontally or vertically by clicking right on the terminal <br>

![image](https://github.com/user-attachments/assets/cf86df3c-9e73-4177-81d4-20035f5c99c7)

## Step 2: Bus Geofence Analysis Integration

**Advanced Feature**: This repository now includes a comprehensive bus geofence analysis module that can be integrated with ROS2 applications for transportation and logistics systems.

### Features:
- Spatial-temporal analysis of bus movements
- Geofence entry/exit event detection
- Real-time flow metrics and cumulative tracking
- Multi-provider support for fleet management

### Quick Start:
```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
python -m pytest tests/

# See documentation
cat docs/bus_geofence_analysis.md
```

For detailed usage instructions, see [`docs/bus_geofence_analysis.md`](docs/bus_geofence_analysis.md).

<footer>

<!--
  <<< Author notes: Footer >>>
  Add a link to get support, GitHub status page, code of conduct, license link.
-->

---

Get help: [Post in our discussion board](https://github.com/orgs/skills/discussions/categories/introduction-to-github) &bull; [Review the GitHub status page](https://www.githubstatus.com/)

&copy; 2024 GitHub &bull; [Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md) &bull; [MIT License](https://gh.io/mit)

</footer>
