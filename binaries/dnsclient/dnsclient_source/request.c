#include "request.h"
#include "dns.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <netinet/in.h>

/* Creates a DNS request packet for the given domain name. Returns a
   pointer to the buffer containing the packet on success. Returns
   null on error and fills the error_message buffer. */
void *build_dns_request_packet(const char *domain_name, int *packet_size, 
			       int *request_id, int request_q_type,
			       char *error_message) {

  struct dns_header header;
  struct dns_question_trailer q_trailer;
  size_t domain_length, question_size, header_size, total_size, token_length;
  char *buffer, *buffer_start, *token_index, *save_pointer;
  char temp_buffer[MAX_DOMAIN_LENGTH + 1];

  /* Calculate the size of the DNS request packet, which is the size of the
     header plus the question section.

     The length of the question section is equal to the length of the domain
     name (where each period character is replaced by the length of the 
     subdomain) +1 to account for the last subdomain (e.g. www.google.com
     would become 3www6google3com). Then add +1 for the null root character
     and the remaining fields in the dns_question_trailer. */
  domain_length = strlen(domain_name);
  if (domain_length > MAX_DOMAIN_LENGTH) {
    sprintf(error_message, "domain name too long (max: %d)", 
	    MAX_DOMAIN_LENGTH); 
    return 0;
  }

  question_size = domain_length + sizeof(struct dns_question_trailer) + 2;
  header_size = sizeof(struct dns_header);
  total_size = question_size + header_size;
  *packet_size = total_size;

  /* Allocate memory for the DNS packet buffer. */
  buffer_start = buffer = (char *)malloc(total_size);
  if (buffer_start == 0) {
    strncpy(error_message, "error allocating memory", ERROR_BUFFER);
    return 0;
  }

  /* Fill out the header struct for a DNS request and copy it into the packet 
     buffer. */
  *request_id = rand() % UINT16_MAX;

  memset(&header, 0, header_size);
  header.id	  = htons(*request_id);
  header.flags	  = htons(DNS_USE_RECURSION);
  header.qd_count = htons(1);
  header.an_count = htons(0);
  header.ns_count = htons(0);
  header.ar_count = htons(0);

  memcpy(buffer, &header, header_size);
  buffer += header_size;

  /* Split up the domain name by the period character and copy each subdomain
     into the buffer, prefixed by the length of the subdomain. First copy the
     domain name into a temp buffer though so it can be manipulated without 
     affecting the original string. */
  strcpy(temp_buffer, domain_name);

  token_index = strtok_r(temp_buffer, ".", &save_pointer);
  while (token_index != 0) {

    /* First copy the length into the buffer, then the rest of the string. The
       string is copied byte by byte to preserve the proper byte ordering. */
    token_length = strlen(token_index);

    /* Verify the subdomain length is less than max. Return if too large. */
    if (token_length > MAX_SUBDOMAIN_LENGTH) {
      sprintf(error_message, "subdomain limited to %d chars", MAX_SUBDOMAIN_LENGTH);
      free(buffer_start);
      return 0;
    }

    /* Copy the string byte by byte. */
    *buffer++ = token_length;
    while ((*buffer++ = *token_index++) != 0);

    /* Move back a byte because we want to overwrite the null terminator
       when copying the next string. */
    buffer--;

    token_index = strtok_r(0, ".", &save_pointer);
  }

  /* Mark the end with a zero length octet for the null label, then copy the 
     last few octets for the question part. */
  *buffer++ = 0;
  q_trailer.q_type  = htons(request_q_type);
  q_trailer.q_class = htons(DNS_INET_ADDR);
  
  memcpy(buffer, &q_trailer, sizeof(struct dns_question_trailer));

  return buffer_start;
}



/* Frees the memory associated with the request packet. */
void free_dns_request_packet(void *buffer) {
  free(buffer);
}
