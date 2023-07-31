#! /usr/bin/env python3

import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np

#mpl.rcParams['axes.autolimit_mode'] = 'round_numbers'

mpl.rcParams['patch.force_edgecolor'] = True
mpl.rcParams['patch.facecolor'] = 'b' 

mpl.rcParams['legend.fancybox'] = False
#mpl.rcParams['legend.loc'] = 'upper right'
mpl.rcParams['legend.numpoints'] = 1 
mpl.rcParams['legend.fontsize'] = 'large'
mpl.rcParams['legend.framealpha'] = None
mpl.rcParams['legend.scatterpoints'] = 3 
mpl.rcParams['legend.edgecolor'] = 'inherit'
#mpl.rcParams['axes.autolimit_mode'] = 'round_numbers'
#mpl.rcParams['axes.xmargin'] = 0 
#mpl.rcParams['axes.ymargin'] = 0 
#mpl.rcParams['xtick.direction'] = 'inout'
#mpl.rcParams['ytick.direction'] = 'inout'
mpl.rcParams['xtick.direction'] = 'in'
mpl.rcParams['ytick.direction'] = 'in'
mpl.rcParams['xtick.top'] = True
mpl.rcParams['ytick.right'] = True
mpl.rcParams['axes.grid'] = True
mpl.rcParams['grid.linewidth'] = 0.5 
mpl.rcParams['grid.color'] = '#000000'
mpl.rcParams['grid.alpha'] = 2./15. # 0.133

#mpl.rcParams['font.family'] = 'Latin Modern Roman'
mpl.rcParams['font.size'] = 12
#mpl.rcParams['mathtext.fontset'] = 'cm'
mpl.rcParams['axes.formatter.useoffset'] = False

fig = plt.figure(figsize=[6, 4])
ax = plt.subplot(111)

bench_x = np.array([103 ,328 ,1098 ,3153 ,8671 ,15881 ,25386])
bench_y = np.array([0.009708738, 0.009146341, 0.009107468, 0.009514748, 0.011071387, 0.018890498, 0.037816119]) * 1000

htcmock_x = np.array([38.4, 122, 407, 1214, 3000, 5054, 10790])
htcmock_y = np.array([0.026041667, 0.024590164, 0.024570025, 0.024711697, 0.032, 0.059358924, 0.08897127]) * 1000

bench_min = min(bench_y)
htcmock_min = min(htcmock_y)
plt.axhline(bench_min, linewidth=0.5, linestyle='--', color='k')
plt.axhline(htcmock_min, linewidth=0.5, linestyle='--', color='k')

ax.plot(htcmock_x, htcmock_y, label = "graph", marker='s')
ax.plot(bench_x, bench_y, label = "independent", marker='d')

plt.yticks([bench_min, htcmock_min], minor = True)

plt.xlabel("Throughput (tasks/s)")
plt.ylabel("Scheduling cost (ms/task)")

plt.xscale("log")
#plt.xlim(left=0)
plt.ylim(bottom=0)
plt.legend()

def SI_fmt(v, *args):
  if v == 0.:
    return "0"
  letters = 'fpnum KMGTPE'
  i = letters.index(' ')
  while (i > 0 and v < 0.999):
    v *= 1000.
    i -= 1
  while (i < len(letters)-1 and v > 999.):
    v /= 1000.
    i += 1
  return "{:g}{}".format(v, letters[i])

def x_formatter(v, *args):
  if "{:g}".format(v)[0] in '346789':
    return ''
  return SI_fmt(v, *args)
ax.xaxis.set_minor_formatter(ticker.FuncFormatter(x_formatter))
ax.xaxis.set_major_formatter(ticker.FuncFormatter(x_formatter))
ax.yaxis.set_minor_formatter(ticker.StrMethodFormatter("{x:.1f}"))
ax.yaxis.set_major_formatter(ticker.ScalarFormatter())

plt.savefig("bench.svg", transparent=True)
plt.savefig("bench.jpg")

plt.show()

