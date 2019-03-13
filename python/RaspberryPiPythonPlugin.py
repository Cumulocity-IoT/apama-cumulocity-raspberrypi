# Copyright © 2010 - 2013 Apama Ltd.
# Copyright © 2013 - 2019 Software AG, Darmstadt, Germany and/or its licensors
# 
# SPDX-License-Identifier: Apache-2.0
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

from apama.eplplugin import EPLPluginBase, EPLAction, Correlator, Event
import time
import sys
from threading import Thread, Lock

# =====================
# Raspberry Pi SenseHat
# =====================

from sense_hat import SenseHat
sense = SenseHat()

	
def getTemperatureFromSenseHat():
    return sense.temp		


def pollTemperature(plugin, interval):
	#temperatures = [32.6, 32.8, 32.9, 32.4, 32.7, 32.8, 32.6, 45]
	#temperatureIdx = 0

	plugin.getLogger().info("***** Temperature is read every " + str(interval) + " seconds")
	while(True):
		try:
			#temperature = temperatures[temperatureIdx]
			#temperatureIdx = temperatureIdx + 1
			#if temperatureIdx > len(temperatures) -1:
			#	temperatureIdx = 0
			
			temperature = round(getTemperatureFromSenseHat(),2)
			plugin.getLogger().info("temperature is " + str(temperature))
			
			evt = Event('Temperature', {"reading": str(temperature)})
			Correlator.sendTo("monitor_messages", evt)
		except:
			plugin.getLogger().error("Poll Thread exception: %s", sys.exc_info()[1])
		time.sleep(interval)


class RaspberryPiPythonPlugin(EPLPluginBase):
	def __init__(self, init):
		super(RaspberryPiPythonPlugin, self).__init__(init)
		self.monitorTemperature()

	def monitorTemperature(self):
		try:
			self.thread = Thread(target=pollTemperature, args=(self, 10), name="Apama Temperature Thread")
			self.thread.start()
			self.getLogger().info("Apama Temperature Thread started")
			return True
		except:
			self.getLogger().error("Failed to start Apama Temperature Thread : %s", sys.exc_info()[1])

