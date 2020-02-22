1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
#!plots.py: conjunto de herramientas para hacer plots de resultados de simulacion
#!Copyright (C) <2018>  <Nicolas Velasquez Giron>
 
#!This program is free software: you can redistribute it and/or modify
#!it under the terms of the GNU General Public License as published by
#!the Free Software Foundation, either version 3 of the License, or
#!(at your option) any later version.
 
#!This program is distributed in the hope that it will be useful,
#!but WITHOUT ANY WARRANTY; without even the implied warranty of
#!MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#!GNU General Public License for more details.
 
#!You should have received a copy of the GNU General Public License
#!along with this program.  If not, see <http://www.gnu.org/licenses/>.
#Algo
 
import pandas as pd 
import numpy as np
import plotly.graph_objs as go
from plotly import tools
from plotly.offline import download_plotlyjs, init_notebook_mode, plot, iplot
 
ColorsDefault = {'blue1': 'rgb(7,255,240)',
    'blue2': 'rgb(24,142,172)',
    'blue3': 'rgb(44,110,154)',
    'green1': 'rgb(12,249,4)',
    'green2': 'rgb(30,154,59)',
    'green3': 'rgb(47,111,62)',
    'red1': 'rgb(7,255,240)',
    'red2': 'rgb(7,255,240)',
    'red3': 'rgb(7,255,240)',
    'amber1': 'rgb(247,143,23)',
    'amber2': 'rgb(218,120,64)',
    'amber3': 'rgb(182,86,62)'}
 
def Plot_Streamflow(StreamDic, Rainfall = None, colors = ColorsDefault,
    **kwargs):
    '''Function to plot streamflow data with dates axis and 
    rainfall
    Parameters:
        - Dates: pandas index dates format.
        - StreamDic: Dictionary with the data and plot properties:
            ej: {'Q1':{data:np.array(data), 
                'dates': pd.Series.index,
                'color': 'rgb(30,114,36)', 
                'lw': 4, 'ls': '--'}}
    Optional:
        - Rainfall: Dictionary with rainfall data with the same 
            structure as StreamDic.'''
    #Data definition
    cont = 0
    data = []
    for k in StreamDic.keys():
        #Set del trace
        try:
            setColor = StreamDic[k]['color']
        except:            
            setColor = np.random.choice(list(ColorsDefault.keys()),1)
            setColor = ColorsDefault[setColor[0]]
        try:
            setWeight = StreamDic[k]['lw']
        except:
            setWeight = kwargs.get('lw',4)
        try:
            setLineStyle = StreamDic[k]['ls']
        except:
            setLineStyle = kwargs.get('ls',None)
        #Traces definitions
        trace = go.Scatter(
            x=StreamDic[k]['dates'],
            y=StreamDic[k]['data'],
            name = k,
            line = dict(color = setColor,
                width = setWeight,
                dash = setLineStyle),
            opacity = 1.0)
        #Update data
        data.append(trace)
     
    #Rainfall 
    if type(Rainfall) == dict:
        trace = go.Scatter(
            x = Rainfall['dates'],
            y = Rainfall['data'],
            line = dict(color = 'blue'),
            opacity = 0.8,
            yaxis='y2',
            fill='tozeroy',
            fillcolor='rgba(0, 102, 153,0.2)'
        )
        data.append(trace)
     
    #Layout definition
    layout = dict(showlegend = False,
        xaxis = dict(
            title='Dates'),
        yaxis=dict(
            title="Streamflow [m3/s]"),
        yaxis2=dict(autorange="reversed",
            title="Caudal [m3/s]",
            overlaying ='y',
            side='right')
        )
 
    fig = dict(data=data, layout=layout)
    iplot(fig)
 
 
def Plot_DurationCurve(StreamDic, Rainfall = None, colors = ColorsDefault,
    Pinf = 0.2, Psup = 99.8, Nint = 50, **kwargs):
    '''Function to plot streamflow data with dates axis and 
    rainfall
    Parameters:
        - Dates: pandas index dates format.
        - StreamDic: Dictionary with the data and plot properties:
            ej: {'Q1':{data:np.array(data), 
                'color': 'rgb(30,114,36)', 
                'lw': 4, 'ls': '--'}}
    Optional:
        - Pinf: Inferior percentile (0.2)
        - Psup: Superior percentile (99.8)
        - Nint: Total intervals (50)
        - Rainfall: Dictionary with rainfall data with the same 
            structure as StreamDic.'''
     
    #Obtains the excedance probability and 
    def GetExcedProb(X):
        Qexc = []
        for p in np.linspace(Pinf,Psup,Nint):
            Qexc.append(np.percentile(X, p))
        return Qexc, np.linspace(Pinf,Psup,Nint)[::-1]/100.
     
    #Data definition
    cont = 0
    data = []
    for k in StreamDic.keys():
        #Set del trace
        try:
            setColor = StreamDic[k]['color']
        except:            
            setColor = np.random.choice(list(ColorsDefault.keys()),1)
            setColor = ColorsDefault[setColor[0]]
        try:
            setWeight = StreamDic[k]['lw']
        except:
            setWeight = kwargs.get('lw',4)
        try:
            setLineStyle = StreamDic[k]['ls']
        except:
            setLineStyle = kwargs.get('ls',None)
        #Values and P(x>X)
        Qexc, P = GetExcedProb(StreamDic[k]['data'])
        #Traces definitions
        trace = go.Scatter(
            x=P,
            y=Qexc,
            name = k,
            line = dict(color = setColor,
                width = setWeight,
                dash = setLineStyle),
            opacity = 1.0)
        #Update data
        data.append(trace)
     
    #Layout definition
    layout = dict(showlegend = False,
        xaxis = dict(
            title='P(x>X)',
            tickfont=dict(
                color='rgb(0, 102, 153)',
                size = 16),
            titlefont=dict(
                color='rgb(0, 102, 153)',
                size = 20),
            ),
        yaxis=dict(
            title="Streamflow [m3/s]",
            tickfont=dict(
                color='rgb(0, 102, 153)',
                size = 16),
            titlefont=dict(
                color='rgb(0, 102, 153)',
                size = 20),
            ),
        )
 
    fig = dict(data=data, layout=layout)
    iplot(fig)