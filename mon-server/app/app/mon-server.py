from util import VerificationType, RequirementProcName, ObjectiveProcName


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


	def evaluate_event (cls):

		