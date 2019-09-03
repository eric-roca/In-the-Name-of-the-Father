#!/usr/bin/python
#!/usr/bin/python

#################################################
#						#
# Code to simulate male cog primogeniture case  #
# Eric Roca Fernandez                           #
# eric.roca-fernandez@univ-amu.fr               #
#						#
################################################# 

# This code generates a two CSV files:
#   1) Data for each manor that exists in period t
#       1.1)  Simulation id
#       1.2)  Manor id (not preserved through simulations)
#       1.3)  Period id
#       1.4)  Production (Y)
#       1.5)  State capacity
#       1.6)  Number of manors
#       1.7)  Investment in state capacity
#       1.8)  Investment in the military
#       1.9)  Absolute/Male-Cognatic primogeniture dummy
#       1.10) Dummy for manors that disappear at the end of period t
#   2) Additional data for period t
#       2.1)  Simulation id
#       2.2)  Period id
#       2.3)  Absolute/Male-Cognatic primogeniture dummy
#       2.4)  Number of removed manors
#       2.5)  Number of marriages


from __future__ import division
import numpy
import sys
import math

f = open('Cognatic.txt', 'w')
f.write('simulation;id;period;Y;capacity;counties;g_optimal;b_optimal;absolute;removed\n')
f.close()
q = open('external_data_absolute.txt','w')
q.write('simulation;period;absolute;total_removed;marriages\n')
q.close()

# Parameters

total_simulations = 1000
periods = 25 
phi = 1.00000000001 
psi = 5/12
pb = 1.2
pg = 1.375 
children = 3
gamma = 1-0.5**children

for simulation in range(total_simulations):
	
	counties = 25 

	# Initialise vectors

	print '#'*10+'Simulation '+str(simulation+1)+'#'*10

        capacity = numpy.zeros(counties).tolist()
	married_last_t = numpy.zeros(counties).tolist()
	b_optimal = []
	g_optimal = []
	Y = numpy.random.uniform(1,2,counties).tolist()

	f = None

	for period_tt in range(periods):
		'''
		print "\n\nPERIOD " + str(period_tt+1)
		'''
		#Optimal values#
		f = open('Cognatic.txt, 'a')
	
		b_optimal = []
		g_optimal = []
	
		# Attribute gender to the heir
		inheritors = numpy.random.binomial(1,1-0.5**children,counties)

		# Optimal choices, closed-form solutions
		for i in range(0,counties):
			g1=(Y[i]*gamma - (1 + capacity[i])*pg*(2 + gamma + 2*gamma*phi) + math.sqrt((1 + capacity[i])**2*pg**2*gamma**2 + Y[i]**2*gamma**2 + 2*pg*Y[i]*(2 - 2*psi + gamma*(4*phi*(1 - psi) + gamma*(-1 + capacity[i] + 2*phi**2*(1 - psi) + 2*psi)))))/(2.0*pg*(1 + gamma + gamma*phi))
                        b1=(gamma*phi*(Y[i] + Y[i]*gamma*phi + (1 + capacity[i])*pg*(1 + gamma*phi) - math.sqrt((1 + capacity[i])**2*pg**2*gamma**2 + Y[i]**2*gamma**2 + 2*pg*Y[i]*(2 - 4*gamma*phi*(-1 + psi) - 2*psi + gamma**2*(-1 + capacity[i] - 2*phi**2*(-1 + psi) + 2*psi)))))/(pb*(1 + gamma*(-1 + phi))*(1 + gamma + gamma*phi))

		        b2=(Y[i]*gamma*phi*(capacity[i] + psi))/((1 + capacity[i])*pb*(1 + gamma*phi))		
				
			if g1 < 0:
				b_optimal.append(numpy.array([b2]))
				g_optimal.append(numpy.array([0]))
			else:
				b_optimal.append(b1)
				g_optimal.append(g1)
					
		# Update state capacity using the optimal solution
		old_capacity = [x for x in capacity]
		capacity = [capacity[i]+g_optimal[i] for i in range(counties)]
		denominator = sum((i**phi*(1+j) for i,j in zip(b_optimal,capacity)))

		# Update manor Y after war
		old_Y = [x for x in Y]
		Y = [b_optimal[i]**phi*(1+capacity[i])/denominator*sum(Y) for i in range(counties)]
		Y = 	numpy.array(Y).reshape(-1,).tolist()

                # Identify winners
		winner = [1 if x>=0 else 0 for x in numpy.subtract(Y,old_Y)]
		
                # Remove manors that are too small
		removed = []
		for i in range(counties):
			if Y[i]<0.01:
				removed.append(1)
			else:
				removed.append(0)

                # Output stats                
		for i in range(0,counties):


			line = str(simulation+100*int(flag))+';'+str(i+1)+';'+str(period_tt+1)+';'+str(old_Y[i])+';'+str(old_capacity[i])+';'+str(counties)+';'+str(g_optimal[i])+';'+str(b_optimal[i])+';0;'+str(removed[i])+'\n'
			f.write(line)
		f.close()

		old_capacity = None
		to_eliminate = []
		to_eliminate_Y = 0
		for i in range(counties):
			if Y[i]<0.01:
				to_eliminate.append(i)
				to_eliminate_Y = to_eliminate_Y + Y[i]
		if len(to_eliminate)>0:
			
			Y = [i for j, i in enumerate(Y) if j not in to_eliminate]
			capacity = [i for j, i in enumerate(capacity) if j not in to_eliminate]
			winner = [i for j, i in enumerate(winner) if j not in to_eliminate]
			inheritors = [i for j, i in enumerate(inheritors) if j not in to_eliminate]
			old_Y = [i for j, i in enumerate(old_Y) if j not in to_eliminate]
	
		counties = counties - len(to_eliminate)
		old_Y = [x + to_eliminate_Y/counties for x in old_Y]
		Y = [x + to_eliminate_Y/counties for x in Y]
                capacity = numpy.array(capacity).reshape(-1).tolist()
		Y = numpy.array(Y).reshape(-1).tolist()
		
		# Generate a vector of heirs-gender-Y
                male = [i for i in zip(inheritors,Y,capacity) if i[0]==1]
                female = [i for i in zip(inheritors,Y,capacity) if i[0]==0]
                lm = None
		lf = None
		dis = None
		marriages = None
		single_women = None
		women_add = None
		# Marriage code, only run this if there are marriages
		if len(male)!=0 and len(female)!=0:
	
			lm = len(male)
			lf = len(female)
	
			# Sort heirs by Y::: the second item in the tuple
			male.sort(key= lambda x: x[1], reverse=True)
			female.sort(key=lambda x: x[1], reverse=True)

			dis = numpy.std(Y)

			marriages = numpy.zeros((len(male),len(female)))
			for i in range(len(male)):
			    for j in range(len(female)):

				if sum(marriages[:,j]) == 1:
					continue
				if abs(male[i][1]-female[j][1])<dis:
				    marriages[i][j]=1
				    break



	

			Y = []
			capacity = []
			for i in range(len(male)):
				if sum(marriages[i])==1:
					for j in range(len(female)):
						if marriages[i][j]==1:
							Y.append(male[i][1]+female[j][1])		
							capacity.append((male[i][2]+female[j][2])/2)
				else:
					Y.append(male[i][1])
					capacity.append(male[i][2])

			single_women = sum(marriages) #Sums are by column, hence if a sum equals 0, that woman does not marry
			for i in range(len(single_women)):
				if single_women[i]==0:
					Y.append(female[i][1])
					capacity.append(female[i][2])
			marriages = sum(sum(marriages))
			

		if len(male)==0 or len(female)==0:
		    marriages = 0


	    	line = str(simulation+100*int(flag))+';'+str(period_tt+1)+';0;'+str(len(to_eliminate))+';'+str(marriages)+'\n'
	    	q = open('external_data_male.txt','a')
		q.write(line)
	        q.close()
	    	line = ''
		
	    	counties = len(Y)
