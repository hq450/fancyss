#ifndef RESPONSE_H
#define RESPONSE_H

#include "dns.h"

struct dns_response *parse_dns_response(void *packet_buffer, 
					int packet_length, 
					int expected_id, 
					const char *domain_name, 
					int *answer_count, 
					char *error_message);

#endif /* RESPONSE_H */
