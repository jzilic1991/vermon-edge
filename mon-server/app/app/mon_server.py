from multiprocessing import Queue

from util import VerificationType, RequirementProcName, ObjectiveProcName, \
	RequirementPattern, ObjectivePattern
from monpoly import Monpoly


def get_tr_patterns (ver_type):

	if ver_type == VerificationType.REQUIREMENT.value:

		return RequirementPattern

	elif ver_type == VerificationType.OBJECTIVE.value:

		return ObjectivePattern


def get_verifiers (ver_type):

	if ver_type == VerificationType.REQUIREMENT.value:

		return create_verifiers (RequirementProcName)

	elif ver_type == VerificationType.OBJECTIVE.value:

		return create_verifiers (ObjectiveProcName)


def create_verifiers (ProcName):

	verifiers = dict ()

	for proc_name in (ProcName):

		mon = Monpoly (Queue (), Queue (), proc_name)
		verifiers[mon] = (mon.get_incoming_queue (), mon.get_outgoing_queue ())
		mon.start ()

	return verifiers


class MonServer:

	def __init__ (self, ver_type):

		self._ver_type = ver_type
		self._verifiers = get_verifiers (self._ver_type)
		self._tr_patterns = get_tr_patterns (self._ver_type)


	def evaluate_trace (cls, trace):

		# find trace pattern that fits given trace
		for tr_pattern in (cls._tr_patterns):

			if tr_pattern.value in trace:

				# iterate verifiers and find which one corresponds to matched trace pattern
				for mon in cls._verifiers.keys ():

					# iterate trace patterns which are supported by a verifier
					for tr_target_pattern in mon.get_trace_patterns ():

						# and compare it with required trace pattern
						if tr_pattern.name == tr_target_pattern.name:

							# route given trace to appropriate verifier via queues
							cls._verifiers[mon][0].put (trace)
							v = cls._verifiers[mon][1].get ()

							# send verdict
							print ("Verdict: " + str(v))

							return v