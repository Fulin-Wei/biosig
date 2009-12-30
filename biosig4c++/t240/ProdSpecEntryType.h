/*
 * Generated by asn1c-0.9.21 (http://lionet.info/asn1c)
 * From ASN.1 module "FEF-IntermediateDraft"
 * 	found in "../annexb-snacc-122001.asn1"
 */

#ifndef	_ProdSpecEntryType_H_
#define	_ProdSpecEntryType_H_


#include <asn_application.h>

/* Including external dependencies */
#include <INTEGER.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Dependencies */
typedef enum ProdSpecEntryType {
	ProdSpecEntryType_unspecified	= 0,
	ProdSpecEntryType_serial_number	= 1,
	ProdSpecEntryType_part_number	= 2,
	ProdSpecEntryType_hw_revision	= 3,
	ProdSpecEntryType_sw_revision	= 4,
	ProdSpecEntryType_fw_revision	= 5,
	ProdSpecEntryType_protocol_revision	= 6
} e_ProdSpecEntryType;

/* ProdSpecEntryType */
typedef INTEGER_t	 ProdSpecEntryType_t;

/* Implementation */
extern asn_TYPE_descriptor_t asn_DEF_ProdSpecEntryType;
asn_struct_free_f ProdSpecEntryType_free;
asn_struct_print_f ProdSpecEntryType_print;
asn_constr_check_f ProdSpecEntryType_constraint;
ber_type_decoder_f ProdSpecEntryType_decode_ber;
der_type_encoder_f ProdSpecEntryType_encode_der;
xer_type_decoder_f ProdSpecEntryType_decode_xer;
xer_type_encoder_f ProdSpecEntryType_encode_xer;

#ifdef __cplusplus
}
#endif

#endif	/* _ProdSpecEntryType_H_ */