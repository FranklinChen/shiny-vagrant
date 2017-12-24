
import pandas as pd
import numpy as np
import datetime
from collections import defaultdict
import re
from collections import Counter
from collections import defaultdict

import seaborn as sns
import shutil
import os,sys,glob

class Corpus:
    def __init__(self):
        print("creating corpus")
        self.fileName = ""
        self.minLen = 1000
        self.counts =defaultdict(lambda: 0)

    def readCSV(self,file):
        print("reading "+file)
        self.fileName = file
        self.corpusname = os.path.basename(file)
        self.corpus  = pd.read_csv(self.fileName,dtype=str)
        print("done reading")
        if "w" in self.corpus:
            self.setupCorpus()

    def isMinLen(self):
        adultLen = 0
        childLen = 0
        if 'Adult' in self.counts:
            adultLen = self.counts['Adult']
        if 'Target_Child' in self.counts:
            childLen = self.counts['Target_Child']
        return(adultLen > self.minLen and childLen > self.minLen and "w" in self.corpus)

    def setupCorpus(self):
#        print(self.corpus.columns)
        self.corpus = self.corpus[['uID','role','w', 't_type']]

        self.corpus['punct'] = ["##"+str(p) for p in self.corpus.t_type]
        self.corpus['w'] = [str(w).strip() for w in self.corpus['w']]
        self.corpus['bag'] = [w.split(" ") for w in self.corpus['w']]
        self.corpus['blen'] = [len(w) for w in self.corpus.bag]
        self.corpus2 = self.corpus.loc[~self.corpus['w'].str.contains("xxx|www|yyy")]
        self.corpus2 = self.corpus2.loc[self.corpus2.blen > 1] # only use utterances with more than 1 word
        self.corpus2['ubag'] = [self.makeNamesUnique(w) for w in self.corpus2['bag']] 
        self.corpus2['tworole']='Adult'
        self.corpus2.loc[self.corpus2.role == "Target_Child",'tworole'] = "Target_Child"
        cc = self.corpus2.tworole.value_counts()
        self.counts = cc
#        print(self.corpus2[1:10])
        print(cc)

    def loadCorpusBuild(self, corpusname, trainProp, trainRole="Adult", testProp=-1, testRole="Adult"):
        print("load corpus "+corpusname)
        self.readCSV(corpusname)
        if self.isMinLen():
            self.setupCorpus()
            self.createTrainTest(trainProp = trainProp, trainRole = trainRole, 
                                         testProp = testProp, testRole = testRole)
            self.makeNgrams()
            self.makeProminence()


    def createTrainTest(self, trainProp, trainRole="Adult", testProp=-1, testRole="Adult"):
        roleTrain = self.corpus2.loc[self.corpus2.tworole == trainRole]
        roleTrain = roleTrain.assign(trainTest = np.random.binomial(1, trainProp, len(roleTrain)))
        self.traininput = roleTrain.loc[roleTrain['trainTest']==1]
        self.traininput = self.traininput.reset_index(drop=True)
        cc = self.traininput.tworole.value_counts()
        cc.index = "train-"+cc.index

        self.counts = self.counts.append(cc)
        self.trainProp = trainProp
        self.trainRole = trainRole

        if testRole == trainRole and testProp < 0:
            self.testinput = roleTrain.loc[roleTrain['trainTest']==0]
        else:
            roleTest = self.corpus2.loc[self.corpus2.tworole == testRole]
            if testProp > 1: # equate test set with another set by setting testProp to the desired number
                testProp = testProp/len(roleTest)
            roleTest = roleTest.assign(trainTest = np.random.binomial(1, testProp, len(roleTest)))
            self.testinput = roleTest.loc[roleTest['trainTest']==1]   
        self.testinput = self.testinput.reset_index(drop=True)
        cc = self.testinput.tworole.value_counts()
        cc.index = "test-"+cc.index
        self.counts = self.counts.append(cc)
        print(self.counts)
        self.testProp = testProp
        self.testRole = testRole


    def makeNamesUnique(self, seq):
        # repeated words in utterances are made unique by adding a number to each one starting from right
        # a boy gave a girl a book would  -> . a2 boy gave a1 girl a book
        # order preserving
        seen = defaultdict(int)
        result = []
        for item in seq[::-1]:
            if seen[item] > 0:
                uniqueitem = item + str(seen[item])
            else:
                uniqueitem = item
            seen[item] = seen[item] + 1
            result.append(uniqueitem)
        return result[::-1]
    
    def makeNgrams(self):
        print("Computing ngrams")
        trainset = self.traininput
        trainsentdf = [[trainset.punct[si], trainset.punct[si]] + trainset.ubag[si] for si in
           range(len(trainset.w)) if type(trainset.w[si]) is not float]
        onewordlist = [w for s in trainsentdf for w in s]
        print(onewordlist[0:20])
        onewordlist.extend(['##p'])
        onewordlistnum = [si for si in range(len(trainsentdf)) for w in trainsentdf[si]]
        self.ngramdf = pd.DataFrame({'n1': pd.Series(onewordlist[:-1]),
                                 'n2': pd.Series(onewordlist[1:]),
                                 'n3': pd.Series(onewordlist[2:]),
                                'snum': pd.Series(onewordlistnum)})
        e = len(self.ngramdf)-2
        self.ngramdf = self.ngramdf.ix[:e]

        print(self.ngramdf.tail())
     #   print(self.traindf.tail())
    
    def makelate(self, e,rl,bg):
        return([ bg[x] for r in rl for x in list(range(r+1,e))[::-1] ][::-1] )

    def makeProminence(self):
        print("Computing prominence stats")
        # this setups the training input for the prominence learners
        trainset = self.traininput
        wholebag = [trainset.ubag[si]+[trainset.punct[si]] for si in
           range(len(trainset.w))]
        lensent = [len(x) for x in wholebag]
        rlist = [list(reversed(range(ll))) for ll in lensent]

        earlyword = [ np.repeat(wholebag[x],rlist[x]) for x in range(len(rlist))]
        lateword=[ self.makelate(lensent[s],rlist[s], wholebag[s]) for s in range(len(rlist))]

        earlywordlist = [w for seq in earlyword for w in seq]
        latewordlist = [w for seq in lateword for w in seq]

        promtraininput = pd.DataFrame({'early': earlywordlist, 'late': latewordlist})
        promtraininput['wholebag'] = [wholebag[lin] for lin in range(len(rlist)) for r in earlyword[lin]]        
        promtraininput['snum'] = [lin for lin in range(len(rlist)) for r in earlyword[lin]]

        self.promdf = promtraininput
        print(self.promdf.head(10))

class Learner:
    def __init__(self, corpusinput):
        self.verbal = True
        self.stats = defaultdict(float)  # initializes each dict value to 0.0
        self.candact = defaultdict(float)
        self.name = "noLearner"
        self.lastword = "PER"
        self.lastword2 = "PER"
        self.numform = ": {:.4f}"  # different algorithms have different size numbers
        self.corpusinput = corpusinput
        self.testset = corpusinput.testinput
        self.spa = 0
        self.printsent = 10
        

    def setupTrainModel(self):
        print("train "+self.name)

    def setupTest(self):
        self.spa = 0
        print("test")
        
    def computeWinner(self,candact, blen):
        npcandact = np.array(candact)
        try:  # this code is a bit complicated
            amax = np.nanargmax( npcandact[::-1] )
        except: # if list of only nan arguments
            amax = 0
        return( blen - amax - 1) 
        
    def test(self):
#        print("testset")
#        print(self.testset[0:5])
        wac=0
        spa=0
        sind = 0
        printmod = int(len(self.testset['ubag'])/10)
        print("printmod "+str(printmod))
        for ind in range(len(self.testset['ubag'])):
            ubag = self.testset.ubag[ind]
            punct = "##"+str(self.testset.t_type[ind])
           # print(ubag)
            self.printpar = False
            if ind % printmod == printmod-1:
                print(ind)
                self.printpar = True
            self.preProcess(punct)
            self.thissentcorr = 1  # sentences are correct until they are wrong
            self.predictRecursive(ubag)

    def updateSPAWACscores(self):
        self.stats["SPA"] = self.stats["SPA"] + self.thissentcorr
        self.stats["SPA ALL"] = self.stats["SPA ALL"] + 1
        self.spa = self.stats["SPA"] * 100.0 / self.stats["SPA ALL"]
        self.wac = self.stats["WAC"] * 100.0 / self.stats["WAC ALL"]
        sentres = "wrong"
        if self.thissentcorr == 1:
            sentres = "correct"  
        if self.printpar:
            print("###### "+self.name+" sent "+sentres+" WAC " + str(round(self.wac,3)) + " SPA " + str(round(self.spa,3)) )
        
    def computeActivationForCandidates(self,bag,blen,ind):
        candact = [0] * blen  # init cand activations
        return(candact)
    
    def preProcess(self,target):
        pass
    
    def postProcess(self,punct):
        pass

    def printCandidates(self,ubag,candact,winnum):
        prubag= list(ubag) # create copy of ubag
        prubag[winnum]=prubag[winnum]+"*"
        s = " ".join(["%s=%.3f" % (v,u) for v,u in zip(prubag,candact)])
        if self.thissentcorr == 0:
            s = s + "  XX "
        print(s)
    
    def predictRecursive(self,ubag):
 #       print(ubag)
        blen = len(ubag)
        if len(ubag)==1:
            self.updateSPAWACscores()
        else:
            target = ubag[0]
            candact = self.computeActivationForCandidates(ubag,blen,0)
            
            # select winner
            winnum = self.computeWinner(candact, blen)
            winner = ubag[winnum]

            winner = re.sub("[0-9]+$", "", winner) # remove numbers
            if winner == target:
                self.stats["WAC"] = self.stats["WAC"] + 1
            else:
                self.thissentcorr = 0 # one error makes sentence wrong
            self.stats["WAC ALL"] = self.stats["WAC ALL"] + 1
            # WAC is word accuracy, which is more consistent than SPA

            if self.printpar:
                self.printCandidates(ubag,candact,winnum)
            
            self.postProcess(target)
            
            self.predictRecursive(ubag[1:len(ubag)])
                
class ChanceLearner(Learner):
    def __init__(self, corpusinput):
        Learner.__init__(self, corpusinput)  # use the super class init
        self.name = 'Chance'

    def predictRecursive(self,ubag):
#        print(ubag)
        blen = len(ubag)
        if len(ubag)==1:
            self.updateSPAWACscores()
        else:
            thisbagchance = 1.0 / blen
            if self.printpar:
                print(thisbagchance)
            self.stats["WAC"] = self.stats["WAC"] + thisbagchance
            self.stats["WAC ALL"] = self.stats["WAC ALL"] + 1
            self.thissentcorr = self.thissentcorr * thisbagchance
            newbag = ubag[1:len(ubag)]
            self.predictRecursive(newbag)

class UnigramLearner(Learner):
    def __init__(self, corpusinput):
        Learner.__init__(self, corpusinput)  # use the super class init
        self.name = 'unigram'

    def setupTrainModel(self):
        print("train "+self.name)
        self.ngramdf = self.corpusinput.ngramdf
        self.unigram = Counter(self.ngramdf['n2'])
        print(self.unigram['the'])
    
    def computeActivationForCandidates(self,bag,blen,ind):
        candact = [self.unigram[i] for i in bag]
        maxact = max(candact)
        candact = [x / (maxact+1) for x in candact]
        return(candact)

class BigramLearner(UnigramLearner):
    def __init__(self, corpusinput):
        Learner.__init__(self, corpusinput)  # use the super class init
        self.name = 'bigram'
        self.lastword = '##p'

    def setupTrainModel(self):
        UnigramLearner.setupTrainModel(self)
        self.bigram = Counter(self.ngramdf['n2'] + "_" + self.ngramdf['n3'])
        self.unigram = Counter(self.ngramdf['n2'])

    def computeActivationForCandidates(self,bag,blen,ind):
        bigrams = [self.bigram[self.lastword+"_"+w] for w in bag]
        # to avoid division by zero, we just add 1
        unigrams = [self.unigram[self.lastword]+1 for w in bag]
        candact = [bigrams[i]/unigrams[i] for i in range(blen)]
        return(candact)
    
    def postProcess(self,word):
        self.lastword = word
        
    def preProcess(self,word):
        self.lastword = word

    def printCandidates(self,ubag,candact,winnum):
        prubag= list(ubag) # create copy of ubag
        prubag[winnum]=prubag[winnum]+"*"
        s = " ".join(["%s=%.3f" % (v,u) for v,u in zip(prubag,candact)])
        s = self.lastword+"->"+s
        if self.thissentcorr == 0:
            s = s + "  XX "
        print(s)

    
class BackwardBigramLearner(UnigramLearner):
    def __init__(self, corpusinput):
        Learner.__init__(self, corpusinput)  # use the super class init
        self.name = 'backbigram'

    def setupTrainModel(self):
        UnigramLearner.setupTrainModel(self)
        self.bigram = Counter(self.ngramdf['n2'] + "_" + self.ngramdf['n3'])
        self.unigram = Counter(self.ngramdf['n2'])

    def computeActivationForCandidates(self,bag,blen,ind):
        bigrams = [self.bigram[self.lastword+"_"+w] for w in bag]
        # to avoid division by zero, we just add 1
        unigrams = [self.unigram[w]+1 for w in bag]
        candact = [bigrams[i]/unigrams[i] for i in range(blen)]
        return(candact)
    
    def postProcess(self,word):
        self.lastword = word
        
    def preProcess(self,word):
        self.lastword = word

    def printCandidates(self,ubag,candact,winnum):
        prubag= list(ubag) # create copy of ubag
        prubag[winnum]=prubag[winnum]+"*"
        s = " ".join(["%s=%.3f" % (v,u) for v,u in zip(prubag,candact)])
        s = self.lastword+"->"+s
        if self.thissentcorr == 0:
            s = s + "  XX "
        print(s)


class TrigramLearner(BigramLearner):
    def __init__(self, corpusinput):
        Learner.__init__(self, corpusinput)  # use the super class init
        self.name = 'trigram'

    def setupTrainModel(self):
        BigramLearner.setupTrainModel(self)
        self.trigram = Counter(self.ngramdf['n1'] + "_" + self.ngramdf['n2'] + "_" + self.ngramdf['n3'])
        self.bigram = Counter(self.ngramdf['n1'] + "_" + self.ngramdf['n2'])

    def postProcess(self,word):
        self.lastword2 = self.lastword
        self.lastword = word
        
    def preProcess(self,word):
        self.lastword2 = word
        self.lastword = word

    def computeActivationForCandidates(self,bag,blen,ind):
        trigrams = [self.trigram[self.lastword2 + "_" + self.lastword + "_" + w] for w in bag]
        # to avoid division by zero, we just add 1
        bigrams = [self.bigram[self.lastword2 + "_" + self.lastword]+1 for w in bag]
        candact = [trigrams[i]/bigrams[i] for i in range(blen)]
        return(candact)

# adjacency learner uses prom stats to compute how often
# two words occur in the same sentence at any distance

class AdjLearner(BigramLearner):
    def __init__(self, corpusinput):
        BigramLearner.__init__(self, corpusinput)  # use the super class init
        self.name = 'adjStats'

    def setupTrainModel(self):
        print('setup model')
        BigramLearner.setupTrainModel(self)
        self.promstats = Counter(self.corpusinput.promdf['early'] + ">" + self.corpusinput.promdf['late'])
 #       print(self.corpusinput.promdf[0:30])
        
    def computeActivationForCandidates(self,bag,blen,ind):
        candafter = [self.promstats[self.lastword + ">" + w] for w in bag]
        candbefore = [self.promstats[w + ">" + self.lastword] for w in bag]
        bigrams = [self.bigram[self.lastword+"_"+w] for w in bag]
        # to avoid division by zero, we just add 1
        candact = [bigrams[i]/(candbefore[i]+candafter[i]+1) for i in range(blen)]
        return(candact)

class ProminenceLearner(AdjLearner):
    def __init__(self, corpusinput):
        AdjLearner.__init__(self, corpusinput)  # use the super class init
        self.name = 'promStats'

    def computeActivationForCandidates(self,bag,blen,ind):
        candact = [0]*blen
        for w2 in bag:
            candafter = [self.promstats[w2 + ">" + w] for w in bag]
            candbefore = [self.promstats[w + ">" + w2] for w in bag]
        # to avoid division by zero, we just add 1
            candact = [candact[i]+ candbefore[i]/(candbefore[i]+candafter[i]+1) for i in range(blen)]
        candact = [c*1.0/blen for c in candact]
        return(candact)


class AdjPromLearner(ProminenceLearner):
    def __init__(self, corpusinput):
        ProminenceLearner.__init__(self, corpusinput)  # use the super class init
        self.name = 'adjPromStats'
        self.prodAdj = 0.3
        self.prodProm = 1 - self.prodAdj

    def writeModelSpec(self, f):
        f.write(","+str(self.prodAdj))
 
    def computeActivationForCandidatesAdj(self,bag,blen,ind):
        candafter = [self.promstats[self.lastword + ">" + w] for w in bag]
        candbefore = [self.promstats[w + ">" + self.lastword] for w in bag]
        bigrams = [self.bigram[self.lastword+"_"+w]+1 for w in bag]
        # to avoid division by zero, we just add 1
        candact = [bigrams[i]/(candbefore[i]+candafter[i]+1) for i in range(blen)]
        return(candact)

    def computeActivationForCandidatesProm(self,bag,blen,ind):
        candact = [0]*blen
        for w2 in bag:
            candafter = [self.promstats[w2 + ">" + w] for w in bag]
            candbefore = [self.promstats[w + ">" + w2] for w in bag]
        # to avoid division by zero, we just add 1
            candact = [candact[i]+ candbefore[i]/(candbefore[i]+candafter[i]+1) for i in range(blen)]
        candact = [c*1.0/blen for c in candact]
        return(candact)

    def computeActivationForCandidates(self,bag,blen,ind):
       # candactProm = super(AdjPromLearner, self).computeActivationForCandidates(bag,blen,ind)
        candactProm = self.computeActivationForCandidatesProm(bag,blen,ind)
        candactAdj = self.computeActivationForCandidatesAdj(bag,blen,ind)
        candact = [(candactProm[i]*self.prodProm + candactAdj[i]*self.prodAdj) for i in range(blen)]
        return(candact)
    
class LearnerIterator:
    def __init__(self):
        self.modelParameters = ""  # default parameters
        self.corpusinput = Corpus()
        self.resultsdf = pd.DataFrame()
        print("LearnerIterator created date="+str(datetime.datetime.now().time()))

    def setClassNames(self,glob):
        self.classnames = glob

    def make_class(self, name):
#        c = globals()[name](self.corpusinput)
        c = self.classnames[name](self.corpusinput)
        return (c)

    def runOneModel(self, modelname,printsent=100):
        print("running model"+modelname)
        self.modelObj = self.make_class(modelname)
        self.modelObj.setupTrainModel()
        self.modelObj.test()
        
    def runAllModels(self):
        modelnameslist = ['ChanceLearner','BigramLearner','TrigramLearner','AdjLearner','ProminenceLearner','AdjPromLearner'] 
        for mn in modelnameslist:
            print("running model"+mn)
            self.modelObj = self.make_class(mn)
            self.modelObj.setupTrainModel()
            self.modelObj.test()
            print("corpus "+self.corpusinput.corpusname)
            print("#### FINAL "+mn+" wac="+str(round(self.modelObj.wac,3))+" spa="+str(round(self.modelObj.spa,3)))
            onerow = pd.DataFrame({'corpus': [self.corpusinput.corpusname],
                                   'modelname': [mn], 
                                   'SPA': [self.modelObj.spa], 
                                   'WAC': [self.modelObj.wac],
                                  'trainRole': [self.corpusinput.trainRole],
                                   'testRole': [self.corpusinput.testRole],
                                   'numTrain': [self.corpusinput.counts['train-'+self.corpusinput.trainRole]],
                                   'numTest': [self.corpusinput.counts['test-'+self.corpusinput.testRole]]
                                  })
            self.resultsdf = self.resultsdf.append(onerow)
            print(self.resultsdf)
            
    def runAllModelsLanguages(self,langlist,outcsv = "results.csv"):
#        print(langlist)
        for lang in langlist:
            self.corpusinput.loadCorpusBuild(lang, trainProp = 0.9) # adult-adult
            self.corpusname = self.corpusinput.corpusname
            if self.corpusinput.isMinLen():
                self.runAllModels()
                self.corpusinput.loadCorpusBuild(lang, trainProp = 1.0, trainRole="Adult", testProp=1.0, testRole="Target_Child")
                self.runAllModels()
                self.resultsdf.to_csv(outcsv, sep=',', encoding='utf-8')
#            self.saveFigure()
    
    def saveFigure(self):
        mark = ['o','<','s','>','*','v','^','d','+','.','x']
        mark.reverse()
        fig=sns.factorplot(x="SPA", y="corpus",hue="modelname",  aspect=1.5, size=6,kind="point",join=True,
            row="testRole",markers = mark*100, data=learnIter.resultsdf)
        sns.plt.show()
        fig.savefig('results.png', bbox_inches='tight')
#        learnIter.resultsdf.to_csv("results.csv", sep=',', encoding='utf-8')


learnIter = LearnerIterator()
learnIter.setClassNames(globals())
langlist = glob.glob('actualcsv/*_*_*_Utterance.csv')  # list of csv files
learnIter.runAllModelsLanguages(langlist,outcsv="bigspa.csv")
