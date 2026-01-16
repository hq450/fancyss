#ifndef REQUEST_H
#define REQUEST_H

void *build_dns_request_packet(const char *domain_name, int *packet_size, 
			       int *request_id, int request_q_type, 
			       char *error_message);
void free_dns_request_packet(void *buffer);

#endif /* REQUEST_H */
