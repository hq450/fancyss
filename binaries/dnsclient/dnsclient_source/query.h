#ifndef QUERY_H
#define QUERY_H

void *query_dns_server(void *request_buffer, int *packet_size, 
		       const char *server, int port, int timeout, int retries, 
		       char *error_message);
void free_response_buffer(void *buffer);
void handle_alarm(int attempted);

#endif /* QUERY_H */
