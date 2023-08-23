from enum import Enum


class ObjectiveProcName (Enum):

	AVAIL_IAAS = "avail-iaas"
	AVAIL_SAAS = "avail-saas"
	REL_DEFECT = "rel-defect"
	REL_FAIL = "rel-fail"
	RESPONSE = "response"
	FAIL_DETECT = "fail-detector"
	TH_REQS = "reqs-throughput"
	TH_PACKETS = "pck-throughput"


class RequirementProcName (Enum):

	REQ1 = "req-1"
	REQ2 = "req-2"
	REQ3 = "req-3"


class TracePattern (Enum):

	STATUS = "status"
	TOTAL_REQS = "totalrequests"
	DEFECT = "defect"
	DOWN = "down"
	RESPONSE_TIME = "responsetime"
	HEARTBEAT = "heartbeat"
	REQUEST = "request"
	PACKETS = "packets"


class RequirementPattern (Enum):

	REQ1 = "req1"
	REQ2 = "req2"
	REQ3 = "req3"


class VerificationType (Enum):

	OBJECTIVE = "obj"
	REQUIREMENT = "req"


class Util (object):

	def determine_trace_patterns (mon_proc_name):

		if mon_proc_name == MonpolyProcName.AVAIL_IAAS or \
			mon_proc_name == MonpolyProcName.AVAIL_SAAS:

			return [TracePattern.STATUS]

		elif mon_proc_name == MonpolyProcName.REL_DEFECT:

			return [TracePattern.DEFECT, TracePattern.TOTAL_REQS]

		elif mon_proc_name == MonpolyProcName.REL_FAIL:

			return [TracePattern.DOWN]

		elif mon_proc_name == MonpolyProcName.RESPONSE:

			return [TracePattern.RESPONSE_TIME]

		elif mon_proc_name == MonpolyProcName.FAIL_DETECT:

			return [TracePattern.HEARTBEAT]

		elif mon_proc_name == MonpolyProcName.TH_REQS:

			return [TracePattern.REQUEST]

		elif mon_proc_name == MonpolyProcName.TH_PACKETS:

			return [TracePattern.PACKETS]